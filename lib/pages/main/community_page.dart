import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/community_event.dart';
import '../../services/community_info_card.dart';
import '../../services/community_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class CommunityPage extends StatefulWidget {
   CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {

  CommunityService communityService = CommunityService();
  List<CommunityEvent> events = [
  ];
  CommunityEvent? selectedEvent;
  bool isLoading = true;

  Position? userPosition;

  @override
  void initState()
  {
    super.initState();
    loadLiveEvents();
  }

  Future<void> getUserLocation() async
  {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled)
    {
      return;
    }
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied)
    {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied)
    {
      return;
    }

    if (permission == LocationPermission.deniedForever)
    {
      return;
    }
    userPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high,);
  }

  Future<void> loadLiveEvents() async
  {

    {
      await getUserLocation();
      double latitude = 53.3498;
      double longitude = -6.2603;

      if (userPosition != null)
      {
        latitude = userPosition!.latitude;
        longitude = userPosition!.longitude;
      }

      final liveEvents = await communityService.fetchLiveEvents(latitude, longitude,
      );

      setState(()
      {
        events = liveEvents.where((event)
        {
          return event.latitude != 0 && event.longitude != 0;
        }).toList();

        if (events.isNotEmpty)
        {
          selectedEvent = events.first;
        }
        isLoading = false;
      });
    }
  }

  Future<void> loadEventsForMap(double latitude, double longitude) async
  {
    final liveEvents = await communityService.fetchLiveEvents(latitude, longitude);
    setState(()
    {
      events = liveEvents.where((event)
      {
        return event.latitude != 0 && event.longitude != 0;
      }).toList();
    });
  }

  double calculateDistance(double eventLat, double eventLng)
  {
    if (userPosition == null)
    {
      return 0;
    }
    double distanceInMeters = Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      eventLat,
      eventLng,
    );

    return distanceInMeters / 1000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: Text('Community'),
      ),
      body: SafeArea(
        child: isLoading
          ? Center(
          child: CircularProgressIndicator(),
        )
        : Column(
        children: [
          Expanded(
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(
              selectedEvent?.latitude ?? 53.3498, selectedEvent?.longitude ?? -6.2603,),
            initialZoom: 12,
            onPositionChanged: (camera, hasGesture)
            {
              if (hasGesture)
              {
                final center = camera.center;
                loadEventsForMap(center.latitude, center.longitude);
              }
            },
            minZoom: 3,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'com.tinytales.app',
            ),
            MarkerLayer(
              markers: events.map((event)
              {
                return Marker(
                  point: LatLng(event.latitude, event.longitude),
                  width: 40, height: 40,
                  child: GestureDetector(
                    onTap: ()
                    {
                      setState(()
                      {
                        selectedEvent = event;
                      });
                    },
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.purpleAccent,
                      size: 40,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          ),
          ),

          if (selectedEvent != null)
            CommunityInfoCard(
              event: selectedEvent!,
              distance: calculateDistance(
              selectedEvent!.latitude,
              selectedEvent!.longitude,
    ),
              onViewEvent:() async
              {
                final url = Uri.parse(selectedEvent!.eventUrl);

                if (await canLaunchUrl(url))
                {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            )
          else
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Tap a marker to view an event',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ),

        ],
      ),
            ),
    );
  }
}
