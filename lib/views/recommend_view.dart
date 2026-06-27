import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recommend_provider.dart';
import '../models/recommendation.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/delight_banner.dart';

class RecommendView extends StatelessWidget {
  const RecommendView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RecommendProvider>(builder: (context, rp, _) {
      return RefreshIndicator(onRefresh: () => rp.load(),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Row(children: [
              Container(width: 24, height: 24, decoration: BoxDecoration(
                color: const Color(0xFFFB7299), borderRadius: BorderRadius.circular(6)),
                child: const Center(child: Text('B', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
              const SizedBox(width: 6),
              Text('为你推荐', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600])),
              const Spacer(),
              Icon(Icons.circle, size: 6, color: rp.online ? const Color(0xFF30B980) : Colors.grey[400]),
              const SizedBox(width: 4),
              Text(rp.online ? '在线' : '离线', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ]))),
          if (!rp.online && !rp.loading)
            SliverToBoxAdapter(child: Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [Icon(Icons.wifi_off, size: 16, color: Colors.orange), SizedBox(width: 8),
                Text('无法连接后端', style: TextStyle(fontSize: 13, color: Colors.orange))]))),
          if (rp.delights.isNotEmpty)
            SliverToBoxAdapter(child: SizedBox(
              height: 180,
              child: PageView.builder(
                itemCount: rp.delights.length,
                itemBuilder: (context, index) {
                  final d = rp.delights[index];
                  return DelightBanner(delight: d, currentIndex: index, totalCount: rp.delights.length,
                    onPrev: null, onNext: null,
                    onView: () => rp.reportClick(Recommendation(id: 0, bvid: d.bvid, title: d.title, coverUrl: d.coverUrl)),
                    onLike: () => rp.respondToDelight(d.bvid, 'like'),
                    onDislike: () => rp.respondToDelight(d.bvid, 'dislike'),
                    onDismiss: () => rp.respondToDelight(d.bvid, 'dismiss'));
                },
              ),
            )),
          if (rp.loading && rp.recommendations.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (rp.recommendations.isEmpty)
            SliverFillRemaining(child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Text('还没有推荐，下拉刷新试试', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              ]),
            ))
          else
            SliverList(delegate: SliverChildListDelegate(
              rp.recommendations.map((rec) => RecommendationCard(
                rec: rec,
                onTap: () { rp.reportClick(rec); },
                onLike: () => rp.submitFeedback(rec.bvid, 'like'),
                onDislike: () => rp.submitFeedback(rec.bvid, 'dislike'),
              )).toList(),
            )),
          if (rp.recommendations.isNotEmpty)
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16),
              child: Center(child: TextButton(onPressed: () => rp.append(), child: Text(rp.loading ? '加载中…' : '加载更多推荐', style: const TextStyle(color: Color(0xFFFB7299))))))),
        ]));
    });
  }
}
