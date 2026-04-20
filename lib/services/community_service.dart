import 'community_event.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CommunityService
{

  final String apiKey ='VUI5bboiSgrXv7FZRszGrs0DAWhiZx65';
  Future<List<CommunityEvent>> fetchLiveEvents(double latitude, double longitude) async
  {
    final url = Uri.parse(
      'https://app.ticketmaster.com/discovery/v2/events.json?apikey=$apiKey&latlong=$latitude,$longitude&radius=50&classificationName=family',);

    final response = await http.get(url);
    if (response.statusCode == 200)
    {
      final data = jsonDecode(response.body);
      if (data['_embedded'] == null || data['_embedded']['events'] == null)
      {
        return [];
      }
      final List eventsJson = data['_embedded']['events'];
      return eventsJson.map((event)
      {
        final venue = event['_embedded'] != null && event['_embedded']['venues'] != null && event['_embedded']['venues'].isNotEmpty
            ? event['_embedded']['venues'][0]
            : null;

        final title = (event['name'] ?? '').toString().toLowerCase();
        final description = (event['info'] ?? '').toString().toLowerCase();
        final classification = event['classifications'] != null &&
            event['classifications'].isNotEmpty
            ? (event['classifications'][0]['segment']?['name'] ?? '').toString().toLowerCase() : '';

        final genre = event['classifications'] != null &&
            event['classifications'].isNotEmpty ? (event['classifications'][0]['genre']?['name'] ?? '').toString().toLowerCase() : '';

        final matchesKeyword =
                title.contains('family') ||
                title.contains('baby') ||
                title.contains('parent') ||
                title.contains('toddler') ||
                title.contains('child') ||
                title.contains('kids') ||
                description.contains('family') ||
                description.contains('baby') ||
                description.contains('parent') ||
                description.contains('toddler') ||
                description.contains('child') ||
                description.contains('kids');

        final matchesCategory =
                classification.contains('family') ||
                genre.contains('family') ||
                genre.contains('children') ||
                genre.contains('education');

        if (!matchesKeyword && !matchesCategory)
        {
          return null;
        }
        return CommunityEvent(
          id: event['id'] ?? '',
          title: event['name'] ?? 'No title',
          description: event['info'] ?? '',
          imageUrl: event['images'] != null && event['images'].isNotEmpty
              ? event['images'][0]['url'] ?? '' : '',

          venueName: venue != null ? (venue['name'] ?? 'Unknown venue') : 'Unknown venue',
          address: venue != null ? (venue['city']?['name'] ?? '') : '',
          latitude: venue != null && venue['location'] != null
              ? double.tryParse(venue['location']['latitude'] ?? '0') ?? 0 : 0,

          longitude: venue != null && venue['location'] != null
              ? double.tryParse(venue['location']['longitude'] ?? '0') ?? 0 : 0,
          startDateTime: DateTime.tryParse(
            event['dates']?['start']?['dateTime'] ?? '',
          ) ??

              DateTime.now(),
          endDateTime: null,
          eventUrl: event['url'] ?? '',
        );
      }).whereType<CommunityEvent>().toList();
    } else
    {
      throw Exception('There\'s been an issue');
    }
  }
}