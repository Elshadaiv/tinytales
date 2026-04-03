import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'community_event.dart';

class CommunityInfoCard extends StatelessWidget
{
  final CommunityEvent event;
  final VoidCallback onViewEvent;
  final double distance;

  CommunityInfoCard(
      {
    super.key,
    required this.event,
    required this.onViewEvent,
        required this.distance,
  });

  @override
  Widget build(BuildContext context)
  {
    return Container(
      margin: EdgeInsets.all(12), padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12, blurRadius: 8, offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: event.imageUrl.isNotEmpty
                ? Image.network(event.imageUrl, width: 90, height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace)
              {
                return Container(
                  width: 90, height: 90,
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[700],
                  ),
                );
              },
            )
                : Container(
              width: 85, height: 85,
              color: Colors.grey[300],
              child: Icon(
                Icons.image,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                Text(
                  DateFormat('EEE, d MMM • HH:mm').format(event.startDateTime),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  event.venueName,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${distance.toStringAsFixed(1)} km away',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onViewEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text("View Event"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}