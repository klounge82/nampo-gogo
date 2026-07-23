import 'package:flutter/material.dart';
import '../services/business_service.dart';
import '../theme/business_theme.dart';

class BusinessProductsScreen extends StatefulWidget {
  const BusinessProductsScreen({super.key});

  @override
  State<BusinessProductsScreen> createState() => _BusinessProductsScreenState();
}

class _BusinessProductsScreenState extends State<BusinessProductsScreen> {
  final BusinessService _businessService = BusinessService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _businessService.getProducts();
      if (mounted) {
        setState(() {
          _products = list;
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

  Future<void> _updateProductStatus(String productId, String newStatus) async {
    try {
      await _businessService.updateProduct(productId, {'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('상품 상태가 [$newStatus](으)로 변경되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
      _loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _inactivateProduct(String productId) async {
    try {
      await _businessService.deleteProduct(productId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('상품 판매가 중지되었습니다. (비활성화)'),
          backgroundColor: Colors.deepOrange,
        ),
      );
      _loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showProductDialog({Map<String, dynamic>? product}) {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?['name'] ?? '');
    final descCtrl = TextEditingController(text: product?['description'] ?? '');
    final priceCtrl = TextEditingController(text: product?['price']?.toString() ?? '');
    final salePriceCtrl = TextEditingController(text: product?['sale_price']?.toString() ?? '');
    final catCtrl = TextEditingController(text: product?['category'] ?? '');
    String status = product?['status'] ?? 'ACTIVE';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? '상품 수정' : '신규 상품 등록', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '상품명 *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '정상가 (원) *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: salePriceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '할인가 (원, 선택)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: catCtrl,
                decoration: const InputDecoration(labelText: '카테고리 (선택)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: '상품 설명 (선택)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setSt) => DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: '상태', border: OutlineInputBorder()),
                  items: ['ACTIVE', 'DRAFT', 'SOLD_OUT', 'INACTIVE']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setSt(() => status = val);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BusinessTheme.primaryTeal,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final priceText = priceCtrl.text.trim();
              if (name.isEmpty || priceText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('상품명과 가격을 입력해 주세요.')),
                );
                return;
              }

              final price = int.tryParse(priceText);
              if (price == null || price < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('올바른 가격(0 이상)을 입력해 주세요.')),
                );
                return;
              }

              int? salePrice;
              if (salePriceCtrl.text.trim().isNotEmpty) {
                salePrice = int.tryParse(salePriceCtrl.text.trim());
                if (salePrice != null && salePrice > price) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('할인가는 정상가 이하이어야 합니다.')),
                  );
                  return;
                }
              }

              final data = {
                'name': name,
                'price': price,
                if (salePrice != null) 'sale_price': salePrice,
                'category': catCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'status': status,
              };

              Navigator.of(ctx).pop();

              try {
                if (isEdit) {
                  await _businessService.updateProduct(product['id'], data);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('상품이 수정되었습니다.'), backgroundColor: Colors.green),
                  );
                } else {
                  await _businessService.createProduct(data);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('새 상품이 등록되었습니다.'), backgroundColor: Colors.green),
                  );
                }
                _loadProducts();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text(isEdit ? '저장' : '등록'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'ACTIVE':
        color = Colors.green;
        label = '판매중';
        break;
      case 'SOLD_OUT':
        color = Colors.orange;
        label = '품절';
        break;
      case 'INACTIVE':
        color = Colors.grey;
        label = '판매중지';
        break;
      case 'DRAFT':
        color = Colors.blue;
        label = '임시저장';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상품 및 메뉴 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        backgroundColor: BusinessTheme.primaryTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('상품 등록', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        ElevatedButton(onPressed: _loadProducts, child: const Text('다시 시도')),
                      ],
                    ),
                  ),
                )
              : _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            '등록된 상품이 없습니다.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showProductDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('첫 상품 등록하기'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BusinessTheme.primaryTeal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _products.length,
                      itemBuilder: (ctx, idx) {
                        final p = _products[idx];
                        final status = p['status'] as String? ?? 'ACTIVE';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _buildStatusBadge(status),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        p['name'] as String? ?? '상품명 미정',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _showProductDialog(product: p),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    Text(
                                      '${p['price']} 원',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: p['sale_price'] != null
                                            ? Colors.grey
                                            : BusinessTheme.darkSlate,
                                        decoration: p['sale_price'] != null
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    if (p['sale_price'] != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '${p['sale_price']} 원 (할인가)',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                if (p['description'] != null &&
                                    (p['description'] as String).isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    p['description'] as String,
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                ],

                                const Divider(height: 24),

                                // Quick Status Action Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (status != 'ACTIVE')
                                      OutlinedButton(
                                        onPressed: () => _updateProductStatus(p['id'], 'ACTIVE'),
                                        child: const Text('판매 시작'),
                                      ),
                                    if (status == 'ACTIVE') ...[
                                      OutlinedButton(
                                        onPressed: () => _updateProductStatus(p['id'], 'SOLD_OUT'),
                                        child: const Text('품절 처리'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: () => _inactivateProduct(p['id']),
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('판매 중지'),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
