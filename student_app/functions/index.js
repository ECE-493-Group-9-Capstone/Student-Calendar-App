const { logger } = require("firebase-functions/v2");
const { onRequest } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { defineSecret } = require("firebase-functions/params");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const axios = require("axios");

initializeApp();
const db = getFirestore();
const locationsCollection = db.collection("locations");
const GOOGLE_MAPS_API_KEY = defineSecret("GOOGLE_MAPS_API_KEY");
const UOFA_EVENTS_BEARER = defineSecret("UOFA_EVENTS_BEARER");
const BEGIN_DATE = "2025/01/01";

const EVENTS_API_URL =
  "https://www.ualberta.ca/api/coveo/rest/search/v2?organizationId=universityofalbertaproductionk9rdz87w";

const EVENTS_HEADERS = {
  authorization: "",
  "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
};

const EVENTS_REQUEST_BODY = {
  aq: "",
  searchHub: "events",
  pipeline: "ualberta-events",
  firstResult: "0",
  numberOfResults: "24",
  sortCriteria: "@ua__event_start_datetime ascending",
};
/**
 * Converts a time in milliseconds to an ISO time string (HH:MM:SS).
 * @param {number} timeInMilliseconds - The time in milliseconds.
 * @returns {string|null} - The converted time string or null if invalid.
 */
function convertTime(timeInMilliseconds) {
  if (
    !timeInMilliseconds ||
    isNaN(timeInMilliseconds) ||
    typeof timeInMilliseconds !== "number"
  ) {
    return null;
  }
  const date = new Date(timeInMilliseconds);
  return isNaN(date.getTime()) ? null : date.toISOString().slice(11, 19);
}
/**
 * Parses a date string into start and end Date objects.
 * @param {string} dateString - The date string to parse.
 * @returns {{startDate: Date|null, endDate: Date|null}} - The parsed start and end dates.
 */
function parseDate(dateString) {
  let startDate = null;
  let endDate = null;
  if (!dateString) {
    return { startDate, endDate };
  }
  logger.log(`[parseDate] Parsing date string: ${dateString}`);
  const rangeSplit = dateString.split(" - ");
  if (rangeSplit.length == 2) {
    startDate = new Date(rangeSplit[0].trim());
    endDate = new Date(rangeSplit[1].trim());
  } else {
    startDate = new Date(dateString.trim());
  }
  logger.log(
    `[parseDate] Parsed date string to startDate: ${startDate}, endDate: ${endDate}`
  );
  return { startDate, endDate };
}
/**
 * Fetches the geographical coordinates for a given location name.
 * @param {string} locationName - The name of the location to geocode.
 * @returns {Promise<{lat: number, lng: number}|null>} - The coordinates or null if not found.
 */
async function getCoordinates(locationName) {
  if (!locationName) {
    logger.warn("[getCoordinates] Location name is empty. Skipping geocoding.");
    return null;
  }

  // check if the location name contains "Online" or "Zoom"
  if (/online|zoom/i.test(locationName)) {
    logger.log(
      `[getCoordinates] Location "${locationName}" is virtual. Skipping geocoding.`
    );
    return null;
  }

  // check Firestore for cached coordinates
  const cachedLocation = await locationsCollection
    .where("name", "==", locationName)
    .limit(1)
    .get();

  if (!cachedLocation.empty) {
    const doc = cachedLocation.docs[0];
    logger.log(`[getCoordinates] Cache hit for location: ${locationName}`);
    return doc.data().coordinates;
  }

  // fetch coordinates from Google Places API
  const PLACES_API_URL = "https://places.googleapis.com/v1/places:searchText";
  const regionCode = "CA";
  const locationRestriction = {
    rectangle: {
      low: { latitude: 49.002, longitude: -120.002 }, // southwest corner of Alberta
      high: { latitude: 60.002, longitude: -109.998 }, // northeast corner of Alberta
    },
  };

  const requestBody = {
    textQuery: locationName,
    regionCode: regionCode,
    locationRestriction: locationRestriction,
    maxResultCount: 1,
  };

  const headers = {
    "Content-Type": "application/json",
    "X-Goog-Api-Key": GOOGLE_MAPS_API_KEY.value(),
    "X-Goog-FieldMask": "places.location",
  };

  try {
    const response = await axios.post(PLACES_API_URL, requestBody, { headers });

    if (response.status !== 200) {
      throw new Error(
        `[getCoordinates] API request failed with status: ${response.status}`
      );
    }

    const data = response.data;

    if (data.places && data.places.length > 0) {
      const place = data.places[0];
      if (place.location) {
        const coordinates = {
          lat: place.location.latitude,
          lng: place.location.longitude,
        };

        // save the coordinates in Firestore
        await locationsCollection.add({
          name: locationName,
          coordinates,
        });

        logger.log(
          `[getCoordinates] Coordinates for ${locationName} cached in Firestore.`
        );
        return coordinates;
      } else {
        logger.warn(
          "[getCoordinates] Location data not found in the response."
        );
        return null;
      }
    } else {
      logger.warn(
        `[getCoordinates] No places found matching the query: ${locationName}`
      );
      return null;
    }
  } catch (error) {
    logger.error(
      `[getCoordinates] Error fetching coordinates from Places API for ${locationName}:`,
      error
    );
    return null;
  }
}
/**
 * Fetches events from the external API starting from a given date.
 * @param {string} [date=BEGIN_DATE] - The starting date for fetching events (YYYY/MM/DD).
 * @returns {Promise<Array>} - A list of event objects.
 */
async function fetchEvents(date = BEGIN_DATE) {
  let events = [];
  let firstResult = 0;
  EVENTS_HEADERS.authorization = UOFA_EVENTS_BEARER.value();
  EVENTS_REQUEST_BODY.aq = `@ua__event_start_datetime>="${date}"`;

  while (true) {
    EVENTS_REQUEST_BODY.firstResult = String(firstResult);

    try {
      const response = await axios.post(EVENTS_API_URL, EVENTS_REQUEST_BODY, {
        headers: EVENTS_HEADERS,
      });

      const responseData = response.data;
      const totalCount = responseData.totalCount || 0;
      const results = responseData.results || [];

      if (totalCount === 0 || results.length === 0) break;

      for (const event of results) {
        const startTimeUnix = event.raw?.ua__event_start_datetime || "TBA";
        const endTimeUnix = event.raw?.ua__event_end_datetime || "TBA";
        const locationName = event.raw?.ua__event_location || null;
        const dateString = event.raw?.ua__event_date_range || null;
        const { startDate, endDate } = parseDate(dateString);

        const eventData = {
          title: event.title,
          description: event.raw?.ua__event_teaser || null,
          startDate: startDate || null,
          endDate: endDate,
          start_time: convertTime(startTimeUnix),
          end_time: convertTime(endTimeUnix),
          location: locationName,
          coordinates: null,
          imageUrl: event.raw?.ua__event_img || "No image available.",
          link: event.clickUri || "No link available.",
        };

        events.push(eventData);
      }

      if (firstResult + 24 >= totalCount) break;
      firstResult += 24;
    } catch (error) {
      logger.error("[fetchEvents] Error fetching events:", error);
      break;
    }
  }
  return events;
}
/**
 * Saves a list of events to Firestore, adding, skipping, or updating as needed.
 * @param {Array} events - The list of event objects to save.
 * @returns {Promise<{addedCount: number, skippedCount: number, updatedCount: number}>} - The counts of added, skipped, and updated events.
 */
async function saveEventsToFirestore(events) {
  const eventsCollection = db.collection("events");
  let addedCount = 0;
  let skippedCount = 0;
  let updatedCount = 0;
  let existingEvents = [];

  for (const event of events) {
    const querySnapshot = await eventsCollection
      .where("title", "==", event.title)
      .get();

    if (querySnapshot.empty) {
      const coordinates = await getCoordinates(event.location);
      event.coordinates = coordinates;
      await eventsCollection.add(event);
      addedCount++;
      existingEvents.push(event);
    } else {
      const existingDoc = querySnapshot.docs[0];
      const existingData = existingDoc.data();
      const fieldsToUpdate = {};
      for (const key in event) {
        if (event[key] !== existingData[key]) {
          fieldsToUpdate[key] = event[key];
        }
      }

      if (fieldsToUpdate.length > 0) {
        await eventsCollection.doc(existingDoc.id).update(fieldsToUpdate);
        logger.log(`[saveEventsToFirestore] Updated event: ${event.title}`);
        updatedCount++;
      } else {
        logger.log(
          `[saveEventsToFirestore] No changes for event: ${event.title}. Skipping.`
        );
        skippedCount++;
      }
    }
  }

  logger.log(
    `[saveEventsToFirestore] Processed ${events.length} events. Added: ${addedCount}, Skipped: ${skippedCount}, Updated: ${updatedCount}`
  );
  return { addedCount, skippedCount, updatedCount };
}
/**
 * Cloud Function to fetch events manually via an HTTP request.
 * @param {Object} req - The HTTP request object.
 * @param {Object} res - The HTTP response object.
 */
exports.fetchEventsOnRequest = onRequest(
  { secrets: ["GOOGLE_MAPS_API_KEY", "UOFA_EVENTS_BEARER"] },
  async (req, res) => {
    logger.log("[fetchEventsOnRequest] Manual fetch initiated");
    const events = await fetchEvents();
    if (events.length > 0) {
      const { addedCount, skippedCount, updatedCount } =
        await saveEventsToFirestore(events);
      res.json({
        processed: events.length,
        added: addedCount,
        skipped: skippedCount,
        updated: updatedCount,
      });
    } else {
      res.json({ message: "[fetchEventsOnRequest] No events fetched." });
    }
  }
);

exports.fetchEventsDaily = onSchedule(
  { secrets: ["GOOGLE_MAPS_API_KEY", "UOFA_EVENTS_BEARER"] },
  "0 2 * * *",
  async () => {
    logger.info(`[fetchEventsDaily] Scheduled fetch initiated at 2 AM.`);
    try {
      const events = await fetchEvents();
      if (events.length > 0) {
        await saveEventsToFirestore(events);
      } else {
        logger.info(
          `[fetchEventsDaily] No events fetched during the scheduled run.`
        );
      }
    } catch (error) {
      logger.error(
        `[fetchEventsDaily] Error during scheduled fetch: ${error.message}`
      );
    }
  }
);
