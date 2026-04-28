import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
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
  List<Map<String, dynamic>> parentResources = [];
  CommunityEvent? selectedEvent;
  bool isLoading = true;
  Map<String, dynamic>? selectedResource;

  Position? userPosition;

  @override
  void initState()
  {
    super.initState();
    loadLiveEvents();
    loadParentResources();
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


  Future<void> loadParentResources() async
  {
    try
    {
      final jsonString = await rootBundle.loadString("assets/community/parent_resources.json");
      final List<dynamic> data = jsonDecode(jsonString);
      setState(()
      {
        parentResources = data.cast<Map<String, dynamic>>();
      });

      print("Loaded ${parentResources.length}");
    }
    catch (e)
    {
      print("Error loading $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F6FB),
      appBar: AppBar(
        backgroundColor: Color(0xFFF7F6FB),
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
                        selectedResource = null;
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
            MarkerLayer(
              markers: parentResources.map((resource)
              {
                return Marker(
                  point: LatLng(resource["latitude"], resource["longitude"]),
                  width: 40, height: 40,
                  child: GestureDetector(
                    onTap: ()
                    {
                      setState(()
                      {
                        selectedResource = resource;
                        selectedEvent = null;
                      });
                    },
                    child: Icon(
                      Icons.location_pin, color: Colors.green,
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
          else if (selectedResource != null)
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(14),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedResource!["name"] ?? "Parent Resource",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    selectedResource!["description"] ?? "Useful local support for parents.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    selectedResource!["address"] ?? "",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async
                    {
                      final url = Uri.parse(selectedResource!["website"]);

                      if (await canLaunchUrl(url))
                      {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Text("Open Website"),
                  ),
                ],
              ),
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
