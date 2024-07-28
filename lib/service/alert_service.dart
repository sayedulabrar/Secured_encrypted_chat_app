import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';

import 'navigation_service.dart';

class AlertService {
  final GetIt _getIt = GetIt.instance;
  late NavigationService _navigationService;

  AlertService() {
    _navigationService = _getIt.get<NavigationService>();
  }

  void showToast({
    required String text, // message to be displayed in the toast
    IconData? icon, // IconData to display on the left of the toast
    String? assetIconPath, // Path to the asset image for the icon
  }) {
    try {
      DelightToastBar(
        position: DelightSnackbarPosition.top, // position of the toast
        autoDismiss: true, // toast will dismiss automatically
        builder: (context) => ToastCard(
          leading: assetIconPath != null
              ? Image.asset(
            assetIconPath,
            width: 28,
            height: 28,
          ) // display image from assets if provided
              : icon != null
              ? Icon(icon, size: 28)
              : null, // display icon if provided
          title: Text(
            text.replaceAll('email', 'userid'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ).show(_navigationService.navigatorKey!.currentContext!);
      // using _navigationService.navigatorKey!.currentContext! to show the message ensures that the toast message
      // is displayed on the current page, regardless of where you are in the navigation stack. This is because
      // the navigatorKey provides a global context that is always available as long as the MaterialApp is running.
    } catch (e) {
      print(e); // log any errors
    }
  }
}
