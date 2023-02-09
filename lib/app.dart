import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:live_tag_geolocator/constant.dart';
import 'package:live_tag_geolocator/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final _tagName = TextEditingController();
  final _tagId = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double lat = 0;
  double long = 0;
  String timestamp = DateTime.now().toString();

  late Timer timer;
  late StreamSubscription<Position> positionStream;

  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  String? logs;

  @override
  void initState() {
    super.initState();
    init();
    timeRefresher();
    getCurrentLocation();
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  void init() async {
    final SharedPreferences prefs = await _prefs;

    if (mounted) {
      setState(() {
        _tagId.text = prefs.getString('tag_id') ?? '';
        _tagName.text = prefs.getString('tag_name') ?? '';
      });
    }
  }

  void timeRefresher() {
    timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        setState(() {
          timestamp = DateTime.now().toString();
        });
      }

      setState(() {
        logs = 'Updating data...';
      });
      Services.updateDb(_tagId.text.trim(), _tagName.text.trim(),
              lat: lat, long: long)
          .then((value) {
        if (value) {
          setState(() {
            logs = "Data saved";
          });
        } else {
          setState(() {
            logs = value;
          });
        }
      });
    });
  }

  void saveTagInfo() async {
    final SharedPreferences prefs = await _prefs;
    setState(() {
      logs = 'Saving...';
    });
    Services.updateDb(_tagId.text.trim(), _tagName.text.trim(),
            lat: lat, long: long)
        .then((value) {
      if (value) {
        setState(() {
          logs = "Data saved";
        });
      } else {
        setState(() {
          logs = value;
        });
      }
    });

    await prefs.setString('tag_id', _tagId.text.trim());
    await prefs.setString('tag_name', _tagName.text.trim());
  }

  void getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      if (mounted) {
        setState(() {
          lat = position == null ? 0 : position.latitude;
          long = position == null ? 0 : position.longitude;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(
                height: 10,
              ),
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 150,
                  width: 150,
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              const Text(
                'Livestock Information',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 20,
              ),
              builTextField(
                  label: 'Tag ID',
                  hint: 'Type unique tag id',
                  icon: Icons.tag_rounded,
                  index: 0,
                  controller: _tagId,
                  validator: ((value) {
                    if (value!.isEmpty) {
                      return 'Tag ID is required';
                    }

                    return null;
                  })),
              builTextField(
                  label: 'Tag Name',
                  hint: 'Type livestock name',
                  icon: Icons.tag_rounded,
                  index: 0,
                  controller: _tagName,
                  validator: ((value) {
                    if (value!.isEmpty) {
                      return 'Tag name is required';
                    }

                    return null;
                  })),
              const SizedBox(
                height: 30,
              ),
              const Text(
                'Livestock Location',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 15,
              ),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.green),
                    borderRadius: BorderRadius.circular(5)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                              text: 'Latitude:',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  overflow: TextOverflow.ellipsis,
                                  fontWeight: FontWeight.bold)),
                          const WidgetSpan(
                            child: SizedBox(width: 8),
                          ),
                          TextSpan(
                              text: lat.toString(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                              text: 'Longitude:',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  overflow: TextOverflow.ellipsis,
                                  fontWeight: FontWeight.bold)),
                          const WidgetSpan(
                            child: SizedBox(width: 8),
                          ),
                          TextSpan(
                              text: long.toString(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                              text: 'Timestamp:',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  overflow: TextOverflow.ellipsis,
                                  fontWeight: FontWeight.bold)),
                          const WidgetSpan(
                            child: SizedBox(width: 8),
                          ),
                          TextSpan(
                              text: timestamp,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                              text: 'Logs:',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  overflow: TextOverflow.ellipsis,
                                  fontWeight: FontWeight.bold)),
                          const WidgetSpan(
                            child: SizedBox(width: 8),
                          ),
                          TextSpan(
                              text: logs ?? 'No logs',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  if (_formKey.currentState!.validate()) {
                    saveTagInfo();
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    _tagId.text.isEmpty ? 'SAVE' : 'UPDATE',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
              )
            ]),
          ),
        ),
      )),
    );
  }

  TextFormField builTextField(
      {required String label,
      required String hint,
      required IconData icon,
      required int index,
      required TextEditingController controller,
      required String? Function(String? value)? validator}) {
    return TextFormField(
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(fontSize: 15),
      maxLength: index == 1 ? 11 : null,
      controller: controller,
      validator: validator,
      autofocus: false,
      decoration: InputDecoration(
          iconColor: Colors.black,
          isCollapsed: false,
          icon: Icon(
            icon,
            size: index == 6 ? 20 : 18,
            color: Colors.black,
          ),
          hintText: hint,
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.3)),
          focusColor: Colors.black,
          floatingLabelBehavior: FloatingLabelBehavior.always),
    );
  }
}
