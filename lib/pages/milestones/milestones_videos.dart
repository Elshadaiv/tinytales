import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';


class MilestoneVideoPage extends StatefulWidget {
  final String title;
  final String youtubeUrl;

  MilestoneVideoPage({
    super.key,
    required this.title,
    required this.youtubeUrl,

  });

  @override
  State<MilestoneVideoPage> createState() => _MilestoneVideoPageState();

}


class _MilestoneVideoPageState extends State<MilestoneVideoPage>
{
  YoutubePlayerController? _controller;


  @override
  void initState()
  {
    super.initState();

    final id = YoutubePlayer.convertUrlToId(widget.youtubeUrl);

    if(id != null)
      {
        _controller = YoutubePlayerController(initialVideoId: id,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
        ),
        );
      }
  }


  @override
  void dispose()
  {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title),
      ),
      body: _controller == null
          ? Center(child: Text("Invalid", style: TextStyle(color: Colors.white)))
          : Center(
        child: YoutubePlayer(
          controller: _controller!,
          showVideoProgressIndicator: true,
        ),
      ),
    );
  }
}
