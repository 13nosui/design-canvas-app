import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/sandbox/mockable_states.dart';
import '../../../core/sandbox/inspectable.dart';
import 'feed_page.styles.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    // CanvasSandbox によって包まれているため、MockFeedStateのダミーデータが流れてくる
    final state = context.watch<FeedState>();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Inspectable(
          id: '__Text__Timeline',
          isText: true,
          child: AppBar(
            // titleの中のInspectableとGestureDetectorを外し、シンプルなTextに戻します
            title: Text('eee', style: FeedAppBarStyle.titleTypography),
            backgroundColor: FeedAppBarStyle.backgroundColor,
            elevation: 1,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: state.tweets.length,
        itemBuilder: (context, index) {
          final tweet = state.tweets[index];
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Inspectable(
                id: 'FeedTweetStyle',
                child: Container(
                  padding: FeedTweetStyle.padding,
                  decoration:
                      const BoxDecoration(border: FeedTweetStyle.border),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(tweet.displayName,
                                      style: FeedTweetStyle.nameTypography,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                      '${tweet.userName} · ${tweet.timeAgo}',
                                      style: FeedTweetStyle.handleTypography,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(tweet.content,
                                style: FeedTweetStyle.contentTypography),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.favorite_border,
                                    size: 16, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text('${tweet.likes}',
                                    style: FeedTweetStyle.statTypography),
                                const SizedBox(width: 16),
                                const Icon(Icons.repeat,
                                    size: 16, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text('${tweet.retweets}',
                                    style: FeedTweetStyle.statTypography),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
Inspectable(
  id: 'NewWidget_1775106543058',
  child: Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey.withOpacity(0.1),
      border: Border.all(color: Colors.grey.withOpacity(0.5), width: 2.0),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Text('New Element (Press T to edit)'),
  ),
),
Inspectable(
  id: 'NewWidget_1775106524359',
  child: Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey.withOpacity(0.1),
      border: Border.all(color: Colors.grey.withOpacity(0.5), width: 2.0),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Text('New Element (Press T to edit)'),
  ),
),
              Inspectable(
                id: 'NewWidget_1775106166804',
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    border: Border.all(
                        color: Colors.grey.withOpacity(0.5), width: 2.0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('New Element (Press T to edit)'),
                ),
              ),
              Inspectable(
                id: 'NewWidget_1775105981724',
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    border: Border.all(
                        color: Colors.grey.withOpacity(0.5), width: 2.0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('New Element (Press T to edit)'),
                ),
              ),
              Inspectable(
                id: 'FeedTweetStyle_copy',
                child: Container(
                  padding: FeedTweetStyle.padding,
                  decoration:
                      const BoxDecoration(border: FeedTweetStyle.border),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(tweet.displayName,
                                      style: FeedTweetStyle.nameTypography,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                      '${tweet.userName} · ${tweet.timeAgo}',
                                      style: FeedTweetStyle.handleTypography,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(tweet.content,
                                style: FeedTweetStyle.contentTypography),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.favorite_border,
                                    size: 16, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text('${tweet.likes}',
                                    style: FeedTweetStyle.statTypography),
                                const SizedBox(width: 16),
                                const Icon(Icons.repeat,
                                    size: 16, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text('${tweet.retweets}',
                                    style: FeedTweetStyle.statTypography),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Inspectable(
                id: 'FeedTweetStyle_copy',
                child: Container(
                  padding: FeedTweetStyle.padding,
                  decoration:
                      const BoxDecoration(border: FeedTweetStyle.border),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(tweet.displayName,
                                      style: FeedTweetStyle.nameTypography,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                      '${tweet.userName} · ${tweet.timeAgo}',
                                      style: FeedTweetStyle.handleTypography,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(tweet.content,
                                style: FeedTweetStyle.contentTypography),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.favorite_border,
                                    size: 16, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text('${tweet.likes}',
                                    style: FeedTweetStyle.statTypography),
                                const SizedBox(width: 16),
                                const Icon(Icons.repeat,
                                    size: 16, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text('${tweet.retweets}',
                                    style: FeedTweetStyle.statTypography),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Inspectable(
                id: 'FeedTweetStyle_copy_copy',
                child: Container(
                  padding: FeedTweetStyle.padding,
                  decoration:
                      const BoxDecoration(border: FeedTweetStyle.border),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(tweet.displayName,
                                      style: FeedTweetStyle.nameTypography,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                      '${tweet.userName} · ${tweet.timeAgo}',
                                      style: FeedTweetStyle.handleTypography,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(tweet.content,
                                style: FeedTweetStyle.contentTypography),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.favorite_border,
                                    size: 16, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text('${tweet.likes}',
                                    style: FeedTweetStyle.statTypography),
                                const SizedBox(width: 16),
                                const Icon(Icons.repeat,
                                    size: 16, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text('${tweet.retweets}',
                                    style: FeedTweetStyle.statTypography),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // AIによるデザイン自動補正のデモ対象
      floatingActionButton: Inspectable(
        id: 'FeedFabStyle',
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: FeedFabStyle.color, // <-紫色のボタン
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
