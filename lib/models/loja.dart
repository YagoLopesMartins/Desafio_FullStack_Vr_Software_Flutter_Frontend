class Loja {
  final int id;
  final String nome;

  Loja({required this.id, required this.nome});

  factory Loja.fromJson(Map<String, dynamic> json) {
    return Loja(id: json['id'], nome: json['nome']);
  }
}
