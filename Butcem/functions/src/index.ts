import * as admin from "firebase-admin";
import {checkAndCreateNotifications} from "./functions";
import {sendNotifications} from "./functions";

admin.initializeApp();

export {checkAndCreateNotifications};
export {sendNotifications};