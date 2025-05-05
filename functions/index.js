const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

exports.sendPairing = functions.https.onCall(async (data, context) => {
  // unwrap payload in case of callable wrapper
  const payload = data.pairId ? data : (data.data || {});
  const pairId = payload.pairId;

  if (!pairId) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing pairId",
    );
  }

  // use pairId (not “code”) to look up the document
  const pairingRef = db.collection("pairingCodes").doc(pairId);
  const snap = await pairingRef.get();

  if (!snap.exists) {
    throw new functions.https.HttpsError(
        "not-found",
        `No pairing code ${pairId} found—maybe it expired or wasn’t 
        generated yet.`,
    );
  }

  const {expiresAt, used} = snap.data();

  if (used) {
    throw new functions.https.HttpsError(
        "failed-precondition",
        "Pairing code already used",
    );
  }

  if (expiresAt.toDate() < new Date()) {
    throw new functions.https.HttpsError(
        "deadline-exceeded",
        "Pairing code expired",
    );
  }

  // mark it as used
  await pairingRef.update({used: true});

  // send the FCM message
  await admin.messaging().send({
    topic: `pair_${pairId}`,
    data: {type: "PAIRED"},
  });

  return {success: true};
});
