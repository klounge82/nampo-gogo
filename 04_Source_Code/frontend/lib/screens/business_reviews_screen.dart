import 'package:flutter/material.dart';
import '../services/business_service.dart';
import '../theme/business_theme.dart';

class BusinessReviewsScreen extends StatefulWidget {
  const BusinessReviewsScreen({super.key});

  @override
  State<BusinessReviewsScreen> createState() => _BusinessReviewsScreenState();
}

class _BusinessReviewsScreenState extends State<BusinessReviewsScreen> {
  final BusinessService _businessService = BusinessService();
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _reviews = [];
  int _totalCount = 0;
  double _averageRating = 0.0;

  bool _photoOnly = false;
  String _sortOption = 'latest'; // 'latest', 'rating_desc', 'rating_asc'

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _businessService.getReviews(
        photoOnly: _photoOnly,
        sort: _sortOption,
      );

      if (mounted) {
        setState(() {
          _reviews = data['reviews'] as List<dynamic>? ?? [];
          _totalCount = data['total_count'] as int? ?? 0;
          _averageRating = (data['average_rating'] as num?)?.toDouble() ?? 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (idx) => Icon(
          idx < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('손님 리뷰 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReviews,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_errorMessage!),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadReviews,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Average Rating Summary Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: BusinessTheme.primaryTeal.withOpacity(0.08),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '매장 평균 평점',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: BusinessTheme.secondarySlate,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    _averageRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: BusinessTheme.darkSlate,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildRatingStars(_averageRating.round()),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                '총 공개 리뷰',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: BusinessTheme.secondarySlate,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_totalCount 개',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: BusinessTheme.primaryTeal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Filter & Sort Control Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('사진 리뷰만'),
                            selected: _photoOnly,
                            onSelected: (val) {
                              setState(() {
                                _photoOnly = val;
                              });
                              _loadReviews();
                            },
                          ),
                          const Spacer(),
                          DropdownButton<String>(
                            value: _sortOption,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                value: 'latest',
                                child: Text('최신순'),
                              ),
                              DropdownMenuItem(
                                value: 'rating_desc',
                                child: Text('평점 높은순'),
                              ),
                              DropdownMenuItem(
                                value: 'rating_asc',
                                child: Text('평점 낮은순'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _sortOption = val;
                                });
                                _loadReviews();
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Reviews List
                    Expanded(
                      child: _reviews.isEmpty
                          ? const Center(
                              child: Text(
                                '등록된 손님 리뷰가 없습니다.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _reviews.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (ctx, idx) {
                                final item = _reviews[idx];
                                final rating = (item['rating'] as num?)?.toInt() ?? 5;
                                final content = item['content'] as String? ?? '';
                                final nickname = item['nickname'] as String? ?? '방문자';
                                final visitVerified = item['visit_verified'] as bool? ?? false;
                                final imgUrl = item['image_url'] as String?;
                                final createdAt = item['created_at'] != null
                                    ? item['created_at'].toString().split('T')[0]
                                    : '';

                                return Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            _buildRatingStars(rating),
                                            const SizedBox(width: 8),
                                            Text(
                                              '$rating.0',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Spacer(),
                                            if (visitVerified) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.verified,
                                                      size: 12,
                                                      color: Colors.green,
                                                    ),
                                                    SizedBox(width: 2),
                                                    Text(
                                                      '방문 인증',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.green,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            Text(
                                              createdAt,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '작성자: $nickname',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: BusinessTheme.secondarySlate,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          content,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                        ),
                                        if (imgUrl != null && imgUrl.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              imgUrl,
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const SizedBox(),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
