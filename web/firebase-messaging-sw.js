// [MODIFIKASI] Firebase Cloud Messaging Service Worker untuk Web background notifications
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBGQLOma37usB4Y9a6_jb0-p_oi9ZcqhlE',
  appId: '1:85098741909:web:1919ea91422ab4cb61db9c',
  messagingSenderId: '85098741909',
  projectId: 'aplikasilaporanpermata',
  authDomain: 'aplikasilaporanpermata.firebaseapp.com',
  storageBucket: 'aplikasilaporanpermata.firebasestorage.app'
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = (payload.notification && payload.notification.title)
    ? payload.notification.title
    : 'Notifikasi Laporan';
  const notificationOptions = {
    body: (payload.notification && payload.notification.body) ? payload.notification.body : '',
    icon: '/favicon.png',
    data: payload.data
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener('install', function(event) {
  self.skipWaiting();
});

self.addEventListener('activate', function(event) {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      for (var i = 0; i < clientList.length; i++) {
        var client = clientList[i];
        if ('focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
