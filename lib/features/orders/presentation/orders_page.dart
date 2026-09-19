import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/api_services.dart';
import '../../../core/services/auth_session.dart';
import '../models/order_summary.dart';
import '../../auth/presentation/login_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  Future<List<OrderSummary>>? _ordersFuture;

  @override
  void initState() {
    super.initState();
    final bool isLoggedIn =
        AuthSession.token != null && AuthSession.token!.isNotEmpty;
    if (isLoggedIn) {
      _ordersFuture = _fetchOrders();
    }
  }

  Future<List<OrderSummary>> _fetchOrders() {
    return _fetchOrdersFromApi();
  }

  Future<List<OrderSummary>> _fetchOrdersFromApi() async {
    final token = AuthSession.token;
    if (token == null || token.isEmpty) {
      return <OrderSummary>[];
    }
    final uri = Uri.parse('${ApiService.baseUrl}/orders')
        .replace(queryParameters: {'page': '1', 'limit': '20'});
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final Map<String, dynamic> data =
          body['data'] as Map<String, dynamic>? ?? {};
      final List<dynamic> orders = data['orders'] as List<dynamic>? ?? [];
      return orders
          .map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final String message =
        body['message'] as String? ?? 'Failed to load orders';
    throw Exception(message);
  }

  Future<void> _refresh() async {
    setState(() {
      _ordersFuture = _fetchOrders();
    });
    await _ordersFuture;
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn =
        AuthSession.token != null && AuthSession.token!.isNotEmpty;

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please login to view your orders.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginPage(),
                    ),
                  );
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    _ordersFuture ??= _fetchOrders();

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<OrderSummary>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(snapshot.error.toString()),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              );
            }
            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  Text('No orders yet.'),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderCard(order: order);
              },
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final String created =
        '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber.isEmpty ? 'Order' : order.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 8),
          Text('Items: ${order.itemCount}'),
          const SizedBox(height: 4),
          Text('Total: ${order.total.toStringAsFixed(0)} EGP'),
          const SizedBox(height: 4),
          Text('Date: $created'),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  Color _color() {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'out_for_delivery':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color().withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: _color(),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
