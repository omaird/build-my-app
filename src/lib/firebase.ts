import { initializeApp, type FirebaseApp } from 'firebase/app';
import { connectAuthEmulator, getAuth, type Auth } from 'firebase/auth';
import {
  connectFirestoreEmulator,
  initializeFirestore,
  persistentLocalCache,
  persistentMultipleTabManager,
  type Firestore,
} from 'firebase/firestore';

let _app: FirebaseApp | undefined;
let _auth: Auth | undefined;
let _db: Firestore | undefined;
let _authEmulatorConnected = false;
let _firestoreEmulatorConnected = false;

function shouldUseEmulators(): boolean {
  return import.meta.env.VITE_USE_FIREBASE_EMULATORS === 'true';
}

function getApp(): FirebaseApp {
  if (_app) return _app;
  _app = initializeApp({
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
    storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
    appId: import.meta.env.VITE_FIREBASE_APP_ID,
  });
  return _app;
}

export function getFirebaseAuth(): Auth {
  if (_auth) return _auth;
  _auth = getAuth(getApp());
  if (shouldUseEmulators() && !_authEmulatorConnected) {
    connectAuthEmulator(_auth, 'http://127.0.0.1:9099', { disableWarnings: true });
    _authEmulatorConnected = true;
  }
  return _auth;
}

export function getDb(): Firestore {
  if (_db) return _db;
  _db = initializeFirestore(getApp(), {
    localCache: persistentLocalCache({
      tabManager: persistentMultipleTabManager(),
    }),
  });
  if (shouldUseEmulators() && !_firestoreEmulatorConnected) {
    connectFirestoreEmulator(_db, '127.0.0.1', 8080);
    _firestoreEmulatorConnected = true;
  }
  return _db;
}
