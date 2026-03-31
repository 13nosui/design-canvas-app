import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/sandbox/mockable_states.dart';
import 'feed_page.styles.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    // CanvasSandbox によって包まれているため、MockFeedStateのダミーデータが流れてくる
    final state = context.watch<FeedState>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView.builder(
        itemCount: state.tweets.length,
        itemBuilder: (context, index) {
          final tweet = state.tweets[index];
          return Container(
            padding: FeedPageStyles.tweetPadding,
            decoration: const BoxDecoration(border: FeedPageStyles.tweetBorder),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(tweet.displayName, style: FeedPageStyles.nameStyle),
                          const SizedBox(width: 5),
                          Text('${tweet.userName} · ${tweet.timeAgo}', style: FeedPageStyles.handleStyle),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(tweet.content, style: FeedPageStyles.contentStyle),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.favorite_border, size: 16, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text('${tweet.likes}', style: FeedPageStyles.statStyle),
                          const SizedBox(width: 16),
                          const Icon(Icons.repeat, size: 16, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text('${tweet.retweets}', style: FeedPageStyles.statStyle),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      // AIによるデザイン自動補正のデモ対象
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: FeedPageStyles.fabColor, // <-紫色のボタン
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
