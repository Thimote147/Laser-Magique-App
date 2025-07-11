import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';
import '../screens/notifications_screen.dart';
import '../../main.dart';

/// Service global pour gérer les notifications Firebase en arrière-plan
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.messageId}');
  
  // Traiter la notification en arrière-plan
  await FirebaseNotificationService._handleBackgroundMessage(message);
}

/// Service pour gérer les notifications push Firebase et locales
class FirebaseNotificationService {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  // Instances des services
  FirebaseMessaging? _firebaseMessaging;
  FlutterLocalNotificationsPlugin? _localNotifications;
  final NotificationService _notificationService = NotificationService();
  
  // État du service
  bool _isInitialized = false;
  String? _fcmToken;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;


  // Configuration pour les notifications locales
  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'laser_magique_notifications',
    'Laser Magique Notifications',
    description: 'Notifications pour les réservations et alertes',
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
  );

  // Getters
  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;

  /// Initialiser le service Firebase
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('FirebaseNotificationService: Initializing...');

      // Initialiser Firebase Core si pas déjà fait
      if (!Firebase.apps.any((app) => app.name == '[DEFAULT]')) {
        await Firebase.initializeApp();
      }

      // Initialiser Firebase Messaging
      _firebaseMessaging = FirebaseMessaging.instance;

      // Initialiser les notifications locales
      await _initializeLocalNotifications();

      // Demander les permissions AVANT d'obtenir le token
      await _requestPermissions();

      // Attendre un peu pour que les permissions soient bien prises en compte sur iOS
      if (Platform.isIOS) {
        await Future.delayed(const Duration(seconds: 1));
      }

      // Obtenir et sauvegarder le token FCM
      await _initializeFCMToken();

      // Configurer les handlers de messages
      await _setupMessageHandlers();

      // S'abonner au topic "all" pour recevoir les notifications générales
      await subscribeToTopic('all');

      _isInitialized = true;
      debugPrint('FirebaseNotificationService: Initialized successfully');

    } catch (e) {
      debugPrint('FirebaseNotificationService: Failed to initialize: $e');
      rethrow;
    }
  }

  /// Initialiser les notifications locales
  Future<void> _initializeLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

    // Configuration Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configuration iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configuration générale
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialiser avec callback pour les clics
    await _localNotifications!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Créer le canal de notification Android
    if (Platform.isAndroid) {
      await _localNotifications!
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  /// Demander les permissions de notification
  Future<void> _requestPermissions() async {
    if (_firebaseMessaging == null) return;

    try {
      debugPrint('🔔 Requesting notification permissions...');
      
      // Demander les permissions Firebase
      final settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('📱 Notification permissions status: ${settings.authorizationStatus}');
      
      if (Platform.isIOS) {
        switch (settings.authorizationStatus) {
          case AuthorizationStatus.authorized:
            debugPrint('✅ iOS notifications authorized');
            break;
          case AuthorizationStatus.denied:
            debugPrint('❌ iOS notifications denied');
            break;
          case AuthorizationStatus.notDetermined:
            debugPrint('⚠️ iOS notifications not determined');
            break;
          case AuthorizationStatus.provisional:
            debugPrint('🔄 iOS notifications provisional');
            break;
        }
      }

      // Demander les permissions locales sur Android 13+
      if (Platform.isAndroid) {
        await _localNotifications!
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
      
    } catch (e) {
      debugPrint('❌ Failed to request permissions: $e');
    }
  }

  /// Initialiser et sauvegarder le token FCM
  Future<void> _initializeFCMToken() async {
    if (_firebaseMessaging == null) return;

    try {
      debugPrint('🔄 Starting FCM token initialization...');
      
      // Vérifier les permissions d'abord
      final settings = await _firebaseMessaging!.getNotificationSettings();
      debugPrint('📱 Current notification settings: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('❌ Notifications not authorized, cannot get FCM token');
        return;
      }

      // Sur iOS, vérifier si on est sur un simulateur
      bool isSimulator = false;
      String? apnsToken;
      
      if (Platform.isIOS) {
        debugPrint('🍎 iOS detected - checking device type...');
        
        // Essayer d'obtenir le token APNS pour déterminer si on est sur simulateur
        for (int i = 0; i < 5; i++) {
          try {
            apnsToken = await _firebaseMessaging!.getAPNSToken();
            if (apnsToken != null) {
              debugPrint('✅ APNS token available: ${apnsToken.substring(0, math.min(20, apnsToken.length))}...');
              debugPrint('📱 Running on real iOS device');
              break;
            }
          } catch (e) {
            debugPrint('⚠️ APNS token error (${i + 1}/5): $e');
          }
          debugPrint('⏳ APNS token not yet available, waiting... (${i + 1}/5)');
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        if (apnsToken == null) {
          debugPrint('⚠️ APNS token not available after 5 attempts');
          debugPrint('📱 Likely running on iOS simulator');
          isSimulator = true;
        }
      }

      // Obtenir le token FCM
      if (Platform.isIOS && isSimulator) {
        debugPrint('🔄 iOS Simulator detected - creating development token...');
        _fcmToken = 'SIMULATOR_TOKEN_${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('🔧 Using development token for simulator: $_fcmToken');
      } else {
        debugPrint('🔄 Attempting to get real FCM token...');
        try {
          _fcmToken = await _firebaseMessaging!.getToken();
          if (_fcmToken != null) {
            debugPrint('✅ FCM Token obtained: ${_fcmToken!.substring(0, math.min(20, _fcmToken!.length))}...');
          } else {
            debugPrint('❌ FCM Token is null');
          }
        } catch (e) {
          debugPrint('❌ FCM Token failed: $e');
          if (Platform.isIOS) {
            _fcmToken = 'IOS_DEV_TOKEN_${DateTime.now().millisecondsSinceEpoch}';
            debugPrint('🔧 Using development token for iOS: $_fcmToken');
          }
        }
      }

      if (_fcmToken == null) {
        debugPrint('❌ FCM Token is still null - creating fallback token');
        if (Platform.isIOS) {
          _fcmToken = 'IOS_FALLBACK_TOKEN_${DateTime.now().millisecondsSinceEpoch}';
          debugPrint('🔧 Using fallback token for iOS: $_fcmToken');
        } else {
          debugPrint('❌ No fallback available for non-iOS platforms');
          return;
        }
      }

      // Sauvegarder le token dans Supabase pour cet utilisateur
      if (_fcmToken != null) {
        await _saveFCMTokenToSupabase();
      }

      // Écouter les changements de token
      _firebaseMessaging!.onTokenRefresh.listen((token) {
        _fcmToken = token;
        debugPrint('FCM Token refreshed: $token');
        _saveFCMTokenToSupabase();
      });

    } catch (e) {
      debugPrint('❌ Failed to get FCM token: $e');
      
      // Fallback pour le développement
      if (Platform.isIOS) {
        _fcmToken = 'IOS_FALLBACK_TOKEN_${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('🔧 Using fallback token for iOS development: $_fcmToken');
        await _saveFCMTokenToSupabase();
      }
    }
  }

  /// Sauvegarder le token FCM dans Supabase
  Future<void> _saveFCMTokenToSupabase() async {
    if (_fcmToken == null) {
      debugPrint('❌ No FCM token to save');
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        debugPrint('❌ No authenticated user to save FCM token for');
        return;
      }

      debugPrint('💾 Saving FCM token to Supabase for user: $userId');
      debugPrint('🔑 FCM Token: ${_fcmToken!.substring(0, 20)}...');

      // Créer ou mettre à jour le token FCM dans une table dédiée
      final response = await supabase.from('user_fcm_tokens').upsert({
        'user_id': userId,
        'fcm_token': _fcmToken,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,platform').select();

      debugPrint('✅ FCM token saved to Supabase successfully');
      debugPrint('📄 Response: $response');
      
      // Vérifier que le token est bien sauvé
      final verification = await supabase
          .from('user_fcm_tokens')
          .select()
          .eq('user_id', userId);
      debugPrint('🔍 Verification - tokens in DB for user: $verification');

    } catch (e) {
      debugPrint('❌ Failed to save FCM token to Supabase: $e');
      // Don't retry automatically to avoid infinite loops
    }
  }

  /// Configurer les handlers de messages
  Future<void> _setupMessageHandlers() async {
    if (_firebaseMessaging == null) return;

    // Handler pour les messages en arrière-plan
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handler pour les messages reçus quand l'app est au premier plan
    _onMessageSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handler pour quand l'app est ouverte via une notification
    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Vérifier si l'app a été ouverte via une notification
    final initialMessage = await _firebaseMessaging!.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Gérer les messages reçus au premier plan
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Foreground message received: ${message.messageId}');
    debugPrint('📄 Message data: ${message.data}');
    debugPrint('📋 Message title: ${message.notification?.title}');
    debugPrint('📝 Message body: ${message.notification?.body}');

    // Convertir et ajouter aux notifications locales
    final notification = _convertRemoteMessageToNotification(message);
    if (notification != null) {
      _notificationService.addNotification(notification);
      debugPrint('✅ Notification added to local service');
    } else {
      debugPrint('❌ Failed to convert remote message to notification');
    }

    // Afficher une notification locale
    _showLocalNotification(message);
    
    // Afficher une notification visuelle dans l'app
    _showInAppNotification(message);
  }

  /// Gérer les messages qui ouvrent l'app
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('App opened via notification: ${message.messageId}');

    // Convertir et ajouter aux notifications locales
    final notification = _convertRemoteMessageToNotification(message);
    if (notification != null) {
      _notificationService.addNotification(notification);
      // Marquer immédiatement comme lue puisque l'utilisateur a cliqué
      _notificationService.markAsRead(notification.id);
    }

    // Naviguer vers l'écran approprié si nécessaire
    _handleNotificationNavigation(message);
  }

  /// Gérer les messages en arrière-plan (méthode statique)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Background message handled: ${message.messageId}');
    
    // Afficher une notification locale même en arrière-plan
    try {
      final notification = message.notification;
      if (notification?.title != null && notification?.body != null) {
        final localNotifications = FlutterLocalNotificationsPlugin();
        
        // Configuration Android
        const androidDetails = AndroidNotificationDetails(
          'laser_magique_notifications',
          'Laser Magique Notifications',
          channelDescription: 'Notifications pour les réservations et alertes',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
        );

        // Configuration iOS
        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const platformDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        // Afficher la notification
        await localNotifications.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          notification!.title!,
          notification.body!,
          platformDetails,
        );
        
        debugPrint('✅ Background notification shown: ${notification.title}');
      }
    } catch (e) {
      debugPrint('❌ Failed to show background notification: $e');
    }
  }

  /// Afficher une notification locale
  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (_localNotifications == null) {
      debugPrint('❌ Local notifications not initialized');
      return;
    }

    try {
      final notification = message.notification;
      if (notification == null) {
        debugPrint('❌ No notification payload in message');
        return;
      }

      debugPrint('🔔 Showing local notification: ${notification.title}');

      // Configuration Android
      final androidDetails = AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF1E88E5),
        enableVibration: true,
        playSound: true,
      );

      // Configuration iOS
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Afficher la notification
      await _localNotifications!.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        notification.title ?? 'Laser Magique',
        notification.body ?? '',
        platformDetails,
        payload: jsonEncode(message.data),
      );

      debugPrint('✅ Local notification shown successfully');

    } catch (e) {
      debugPrint('❌ Failed to show local notification: $e');
    }
  }

  /// Afficher une notification visuelle dans l'app
  void _showInAppNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final title = notification.title ?? '';
    final body = notification.body ?? '';
    final visualKey = '$title:$body';

    // Vérifier si cette notification visuelle n'a pas déjà été affichée
    if (!_notificationService.hasRecentVisualNotification(visualKey)) {
      _notificationService.markVisualNotificationShown(visualKey);
      
      // Utiliser le navigatorKey global
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        _showTopNotification(context, message);
      }
    } else {
      debugPrint('FirebaseNotificationService: Visual notification already shown: $title');
    }
  }

  /// Afficher une notification en haut de l'écran avec animation
  void _showTopNotification(BuildContext context, RemoteMessage message) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.only(top: 50, left: 16, right: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.notification?.title ?? 'Notification',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (message.notification?.body != null) ...[
                          SizedBox(height: 4),
                          Text(
                            message.notification!.body!,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(); // Fermer la notification
                      // Ouvrir la page des notifications
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Voir',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      barrierDismissible: true,
      barrierLabel: 'Fermer notification',
      barrierColor: Colors.transparent,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0.0, -1.0), // Commence en haut (hors écran)
            end: Offset(0.0, 0.0),    // Arrive à sa position finale
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          )),
          child: child,
        );
      },
    );

    // Fermer automatiquement après 4 secondes
    Timer(Duration(seconds: 4), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  /// Callback quand une notification locale est tapée
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationNavigationFromData(data);
      } catch (e) {
        debugPrint('Failed to parse notification payload: $e');
      }
    }
  }

  /// Naviguer selon le type de notification
  void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;
    _handleNotificationNavigationFromData(data);
  }

  void _handleNotificationNavigationFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    // Cette navigation sera gérée par l'app principale
    switch (type) {
      case 'bookingAdded':
      case 'bookingCancelled':
      case 'bookingDeleted':
        // Naviguer vers les réservations
        break;
      case 'stockAlert':
      case 'stockUpdate':
        // Naviguer vers le stock
        break;
      default:
        // Naviguer vers les notifications
        break;
    }
  }

  /// Convertir un RemoteMessage en AppNotification
  AppNotification? _convertRemoteMessageToNotification(RemoteMessage message) {
    try {
      final data = message.data;
      final notification = message.notification;

      return AppNotification(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: notification?.title ?? data['title'] ?? 'Notification',
        message: notification?.body ?? data['message'] ?? '',
        type: NotificationType.values.firstWhere(
          (type) => type.name == data['type'],
          orElse: () => NotificationType.systemUpdate,
        ),
        priority: NotificationPriority.values.firstWhere(
          (priority) => priority.name == data['priority'],
          orElse: () => NotificationPriority.medium,
        ),
        timestamp: DateTime.now(),
        data: data.isNotEmpty ? Map<String, dynamic>.from(data) : null,
        isRead: false,
        createdBy: data['created_by'] as String?,
      );
    } catch (e) {
      debugPrint('Failed to convert RemoteMessage: $e');
      return null;
    }
  }

  /// Envoyer une notification push via FCM
  Future<void> sendPushNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    String? targetToken,
    List<String>? targetTokens,
    String? topic,
  }) async {
    try {
      // Cette méthode sera utilisée côté serveur/Supabase
      // Ici on peut implémenter l'envoi direct si besoin
      debugPrint('Push notification prepared: $title');
      
    } catch (e) {
      debugPrint('Failed to send push notification: $e');
    }
  }

  /// Nettoyer les ressources
  void dispose() {
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _isInitialized = false;
  }

  /// S'abonner à un topic FCM
  Future<void> subscribeToTopic(String topic) async {
    if (_firebaseMessaging != null) {
      await _firebaseMessaging!.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    }
  }

  /// Se désabonner d'un topic FCM
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_firebaseMessaging != null) {
      await _firebaseMessaging!.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    }
  }
}