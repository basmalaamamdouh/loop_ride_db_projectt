import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CommonMethods {
  checkConnectivity(BuildContext
  context) async //it checks the wifi connection to only the mobile phones
      {
    var connectionResult = await Connectivity().checkConnectivity();

    if (connectionResult != ConnectivityResult.mobile &&
        connectionResult != ConnectivityResult.wifi) //same card internet
        {
      if (!context.mounted) return;
      displaysnackBar("No internet connection ", context);
    }
  }

  displaysnackBar(String messageText, BuildContext context) {
    var snackBar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}