import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenciamento de Loja',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ProductScreen(),
    );
  }
}

class ProductScreen extends StatefulWidget {
  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<Map<String, dynamic>> products = [];
  int currentPage = 1;
  int totalPages = 1;
  int itemsPerPage = 10;
  bool isLoading = false;

  final TextEditingController codigoController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController custoController = TextEditingController();

  void _onPageChanged(int newPage) {
    setState(() {
      currentPage = newPage;
      products.clear();
      _buscar(newPage);
    });
  }

  @override
  void initState() {
    super.initState();
    _buscar(currentPage);
  }

  Future<void> _deleteProduct(int productId) async {
    const String baseUrl = 'http://localhost:5000';

    final response =
        await http.delete(Uri.parse('$baseUrl/produtos/$productId'));

    if (response.statusCode == 201) {
      setState(() {
        products.removeWhere((product) => product['id'] == productId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produto excluído com sucesso')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir produto')),
      );
    }
  }

  Future<void> _buscar(int page) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    const String baseUrl = 'http://localhost:5000';

    final String codigo = codigoController.text;
    final String descricao = descricaoController.text;
    final String custo = custoController.text;

    String url = '$baseUrl/produtos?page=$page&per_page=$itemsPerPage';
    if (codigo.isNotEmpty) url += '&codigo=$codigo';
    if (descricao.isNotEmpty) url += '&descricao=$descricao';
    if (custo.isNotEmpty) url += '&custo=$custo';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonResponse = convert.jsonDecode(response.body);

      setState(() {
        currentPage = jsonResponse['page'];
        totalPages = jsonResponse['pages'];
        products.addAll((jsonResponse['produtos'] as List)
            .map((product) => {
                  'id': product['id'],
                  'descricao': product['descricao'],
                  'custo': product['custo'],
                })
            .toList());
      });
    } else {
      print('[Erro] ao buscar produtos: ${response.statusCode}');
    }

    setState(() {
      isLoading = false;
    });
  }

  void _filterProducts() {
    setState(() {
      currentPage = 1;
      products.clear();
      _buscar(currentPage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Consulta de Produto'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _filterProducts,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: codigoController,
                    decoration: InputDecoration(
                      labelText: 'Código',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: descricaoController,
                    decoration: InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: custoController,
                    decoration: InputDecoration(
                      labelText: 'Custo',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    child: ListTile(
                      title: Text('ID: ${product['id']}'),
                      subtitle: Text('Descrição: ${product['descricao']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteProduct(product['id']),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (isLoading) CircularProgressIndicator(),
            if (products.length >= itemsPerPage)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: currentPage > 1
                        ? () => _onPageChanged(currentPage - 1)
                        : null,
                  ),
                  Text('$currentPage de $totalPages'),
                  IconButton(
                    icon: Icon(Icons.arrow_forward),
                    onPressed: currentPage < totalPages
                        ? () => _onPageChanged(currentPage + 1)
                        : null,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
