import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meu_caderninho/screens/novo_gasto_screen.dart';
import 'editar_grupo_screen.dart';

class GrupoDetalhesScreen extends StatefulWidget {
  final String grupoId;

  const GrupoDetalhesScreen({super.key, required this.grupoId});

  @override
  State<GrupoDetalhesScreen> createState() => _GrupoDetalhesScreenState();
}

class _GrupoDetalhesScreenState extends State<GrupoDetalhesScreen>
    with TickerProviderStateMixin {
  final TextEditingController _buscaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _filtroMembroId; // mover para o State da tela
  List<Map<String, dynamic>> _categorias = [];
  String? _categoriaSelecionada;

  String _nomeGrupo = '';
  List<String> _participantes = [];

  late TabController _innerTabController;

  @override
  void initState() {
    super.initState();
    _carregarGrupo();
    _innerTabController = TabController(length: 3, vsync: this);
  }

  Future<void> _carregarGrupo() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('grupos')
            .doc(widget.grupoId)
            .get();
    if (doc.exists) {
      setState(() {
        _nomeGrupo = doc['nome'] ?? '';
        _participantes = List<String>.from(doc['participantes'] ?? []);
      });
    }
  }

  Future<void> _adicionarUsuario(String usuarioId) async {
    if (_participantes.contains(usuarioId)) return;

    await FirebaseFirestore.instance
        .collection('grupos')
        .doc(widget.grupoId)
        .update({
          'participantes': FieldValue.arrayUnion([usuarioId]),
        });

    setState(() {
      _participantes.add(usuarioId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuário adicionado com sucesso!')),
    );
  }

  Future<void> _enviarConvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite um e-mail válido!')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('convites').add({
      'grupoId': widget.grupoId,
      'email': email,
      'status': 'pendente',
      'enviadoEm': FieldValue.serverTimestamp(),
      'enviadoPor': FirebaseAuth.instance.currentUser?.uid,
    });

    _emailController.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Convite enviado para $email')));
  }

  @override
  void dispose() {
    _buscaController.dispose();
    _emailController.dispose();
    _innerTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_nomeGrupo.isNotEmpty ? _nomeGrupo : 'Grupo'),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [Tab(text: 'Dashboard'), Tab(text: 'Adicionar Membros')],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => EditarGrupoScreen(
                          grupoId: widget.grupoId,
                          nomeAtual: _nomeGrupo,
                        ),
                  ),
                );
                await _carregarGrupo();
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [_buildDashboardTab(), _buildAdicionarMembroTab()],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total no mês
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('grupos')
                    .doc(widget.grupoId)
                    .collection('gastos')
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final gastos = snapshot.data!.docs;
              double total = gastos.fold(
                0.0,
                (acc, gasto) => acc + (gasto['valor'] ?? 0.0),
              );

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: const Color(0xFFFFF7D1),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total no Grupo',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'R\$ ${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Saldos por membro
          const Text(
            'Saldos',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('grupos')
                    .doc(widget.grupoId)
                    .collection('gastos')
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              final gastos = snapshot.data!.docs;
              if (gastos.isEmpty)
                return const Text('Nenhum saldo para mostrar.');

              // Calcular saldos
              final Map<String, double> saldos = {};
              for (var gasto in gastos) {
                final valorTotal = (gasto['valor'] ?? 0.0) as double;
                final divididoEntre = List<String>.from(
                  gasto['divididoEntre'] ?? [],
                );
                final valorPorPessoa = valorTotal / divididoEntre.length;

                for (var participanteId in divididoEntre) {
                  saldos.update(
                    participanteId,
                    (valor) => valor + valorPorPessoa,
                    ifAbsent: () => valorPorPessoa,
                  );
                }
              }

              return StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('usuarios')
                        .snapshots(),
                builder: (context, usuarioSnapshot) {
                  if (!usuarioSnapshot.hasData) return const SizedBox.shrink();

                  final usuarios = usuarioSnapshot.data!.docs;
                  final participantesComSaldo =
                      usuarios
                          .where((u) => _participantes.contains(u.id))
                          .toList();

                  return Column(
                    children:
                        participantesComSaldo.map((usuario) {
                          final id = usuario.id;
                          final nome = usuario['nome'] ?? '';
                          final avatarUrl = usuario['avatarUrl'];
                          final saldo = saldos[id] ?? 0.0;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading:
                                avatarUrl != null
                                    ? CircleAvatar(
                                      backgroundImage: NetworkImage(avatarUrl),
                                    )
                                    : CircleAvatar(
                                      child: Text(
                                        nome.isNotEmpty ? nome[0] : '?',
                                      ),
                                    ),
                            title: Text(nome),
                            trailing: Text(
                              'R\$ ${saldo.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // Filtro por membro
          const Text(
            'Filtrar por membro',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('usuarios').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final usuarios =
                  snapshot.data!.docs
                      .where((u) => _participantes.contains(u.id))
                      .toList();
              return DropdownButtonFormField<String>(
                value: _filtroMembroId,
                hint: const Text('Todos os membros'),
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Todos os membros'),
                  ),
                  ...usuarios.map(
                    (u) => DropdownMenuItem<String>(
                      value: u.id,
                      child: Text(u['nome'] ?? ''),
                    ),
                  ),
                ],
                onChanged: (valor) {
                  setState(() {
                    _filtroMembroId = valor;
                  });
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // Botão Adicionar Gasto
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _abrirModalNovoGasto(),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Gasto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC727),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Gastos Recentes agrupados por mês
          const Text(
            'Gastos Recentes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('grupos')
                    .doc(widget.grupoId)
                    .collection('gastos')
                    .orderBy('data', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final gastos = snapshot.data!.docs;
              if (gastos.isEmpty) return const Text('Nenhum gasto registrado.');

              final Map<String, List<QueryDocumentSnapshot>> gastosPorMes = {};

              for (var gasto in gastos) {
                final data = (gasto['data'] as Timestamp?)?.toDate();
                if (data == null) continue;

                final mesAno =
                    '${data.month.toString().padLeft(2, '0')}/${data.year}';
                gastosPorMes.putIfAbsent(mesAno, () => []).add(gasto);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    gastosPorMes.entries.map((entry) {
                      final mesAno = entry.key;
                      final gastosDoMes = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              mesAno,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...gastosDoMes
                              .where((gasto) {
                                if (_filtroMembroId == null) return true;
                                final divididoEntre = List<String>.from(
                                  gasto['divididoEntre'] ?? [],
                                );
                                return divididoEntre.contains(_filtroMembroId);
                              })
                              .map((gasto) {
                                final dados =
                                    gasto.data() as Map<String, dynamic>? ?? {};
                                final nome = dados['nome'] ?? '';
                                final valor = dados['valor'] ?? 0.0;
                                final categoriaNome =
                                    dados['categoria'] ?? 'Outros';
                                final int? iconeCategoriaCodePoint =
                                    dados['iconeCategoria'];
                                print('iconeCategoriaCodePoint');
                                print(gasto.data());

                                IconData categoriaIcone;
                                if (iconeCategoriaCodePoint != null) {
                                  categoriaIcone = IconData(
                                    iconeCategoriaCodePoint,
                                    fontFamily: 'MaterialIcons',
                                  );
                                } else {
                                  categoriaIcone =
                                      Icons.attach_money; // Ícone padrão
                                }

                                final divididoEntre = List<String>.from(
                                  gasto['divididoEntre'] ?? [],
                                );

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.amber.shade200,
                                    child: Icon(
                                      categoriaIcone,
                                      color: Colors.black,
                                    ),
                                  ),
                                  title: Text(nome),

                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        categoriaNome, // <- aqui você mostra a categoria
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      FutureBuilder<QuerySnapshot>(
                                        future:
                                            FirebaseFirestore.instance
                                                .collection('usuarios')
                                                .where(
                                                  FieldPath.documentId,
                                                  whereIn: divididoEntre,
                                                )
                                                .get(),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData)
                                            return const Text('Carregando...');
                                          final usuarios = snapshot.data!.docs;
                                          final nomes = usuarios
                                              .map((u) => u['nome'] ?? '')
                                              .join(', ');
                                          return Text(
                                            'R\$ ${valor.toStringAsFixed(2)}\n$nomes',
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'editar') {
                                        _editarGasto(gasto.id);
                                      } else if (value == 'excluir') {
                                        _excluirGasto(gasto.id);
                                      }
                                    },
                                    itemBuilder:
                                        (context) => const [
                                          PopupMenuItem(
                                            value: 'editar',
                                            child: Text('Editar'),
                                          ),
                                          PopupMenuItem(
                                            value: 'excluir',
                                            child: Text('Excluir'),
                                          ),
                                        ],
                                  ),
                                );
                              })
                              .toList(),
                        ],
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _abrirModalNovoGasto() {
    final TextEditingController _nomeGastoController = TextEditingController();
    final TextEditingController _valorGastoController = TextEditingController();
    String _categoriaSelecionada = 'Outros';
    DateTime? _dataSelecionada;
    List<String> participantesSelecionados = [];
    bool _isLoading = false;
    int? iconeSelecionadoCodePoint;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Novo Gasto',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _nomeGastoController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do gasto',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _valorGastoController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor (R\$)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dataSelecionada ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _dataSelecionada = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data do gasto',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dataSelecionada != null
                                  ? '${_dataSelecionada!.day}/${_dataSelecionada!.month}/${_dataSelecionada!.year}'
                                  : 'Selecionar data',
                            ),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    FutureBuilder<QuerySnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('categorias')
                              .where(
                                'usuarioId',
                                isEqualTo:
                                    FirebaseAuth.instance.currentUser!.uid,
                              )
                              .where('ativo', isEqualTo: true)
                              .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );

                        final categorias = snapshot.data!.docs;

                        if (categorias.isEmpty) {
                          return const Text('Nenhuma categoria cadastrada.');
                        }

                        // ⚡ Corrige seleção inicial
                        if (_categoriaSelecionada == null ||
                            !categorias.any(
                              (doc) => doc['nome'] == _categoriaSelecionada,
                            )) {
                          _categoriaSelecionada = categorias.first['nome'];
                        }

                        return DropdownButtonFormField<String>(
                          value: _categoriaSelecionada,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              categorias.map((doc) {
                                final nomeCategoria = doc['nome'];
                                final iconeCategoria = doc['icone'];

                                return DropdownMenuItem<String>(
                                  value: nomeCategoria,
                                  child: Row(
                                    children: [
                                      Icon(
                                        IconData(
                                          iconeCategoria,
                                          fontFamily: 'MaterialIcons',
                                        ),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(nomeCategoria),
                                    ],
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _categoriaSelecionada = value ?? 'Outros';
                              // Quando mudar a categoria, também buscar o icone correspondente:
                              final categoriaSelecionada = categorias
                                  .firstWhere(
                                    (cat) =>
                                        cat['nome'] == _categoriaSelecionada,
                                    orElse:
                                        () =>
                                            throw Exception(
                                              'Categoria não encontrada',
                                            ),
                                  );
                              if (categoriaSelecionada != null) {
                                iconeSelecionadoCodePoint =
                                    categoriaSelecionada['icone'];
                              } else {
                                iconeSelecionadoCodePoint =
                                    Icons.attach_money.codePoint; // Default
                              }
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Dividir entre:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    SizedBox(
                      height: 100,
                      child: FutureBuilder<QuerySnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('usuarios')
                                .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          final usuarios =
                              snapshot.data!.docs
                                  .where(
                                    (doc) => _participantes.contains(doc.id),
                                  )
                                  .toList();

                          return ListView(
                            scrollDirection: Axis.horizontal,
                            children:
                                usuarios.map((usuario) {
                                  final id = usuario.id;
                                  final nome = usuario['nome'] ?? '';
                                  final avatarUrl = usuario['avatarUrl'];
                                  final selecionado = participantesSelecionados
                                      .contains(id);

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (selecionado) {
                                          participantesSelecionados.remove(id);
                                        } else {
                                          participantesSelecionados.add(id);
                                        }
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Column(
                                        children: [
                                          CircleAvatar(
                                            radius: 28,
                                            backgroundColor:
                                                selecionado
                                                    ? Colors.blue.shade200
                                                    : Colors.grey.shade300,
                                            backgroundImage:
                                                avatarUrl != null
                                                    ? NetworkImage(avatarUrl)
                                                    : null,
                                            child:
                                                avatarUrl == null
                                                    ? Text(
                                                      nome.isNotEmpty
                                                          ? nome[0]
                                                          : '?',
                                                    )
                                                    : null,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            nome,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed:
                            _isLoading
                                ? null
                                : () async {
                                  final nomeGasto =
                                      _nomeGastoController.text.trim();
                                  final valorGasto =
                                      double.tryParse(
                                        _valorGastoController.text.trim(),
                                      ) ??
                                      0.0;

                                  if (nomeGasto.isEmpty ||
                                      valorGasto <= 0 ||
                                      _dataSelecionada == null ||
                                      participantesSelecionados.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Preencha todos os campos obrigatórios.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() => _isLoading = true);

                                  int? iconeSelecionadoCodePoint;

                                  try {
                                    final categoriasSnapshot =
                                        await FirebaseFirestore.instance
                                            .collection('categorias')
                                            .where(
                                              'nome',
                                              isEqualTo: _categoriaSelecionada,
                                            )
                                            .get();

                                    if (categoriasSnapshot.docs.isNotEmpty) {
                                      final categoriaDoc =
                                          categoriasSnapshot.docs.first;
                                      iconeSelecionadoCodePoint =
                                          categoriaDoc['icone']; // Busca o codePoint aqui
                                    }
                                  } catch (e) {
                                    print(
                                      'Erro ao buscar ícone da categoria: $e',
                                    );
                                  }

                                  await FirebaseFirestore.instance
                                      .collection('grupos')
                                      .doc(widget.grupoId)
                                      .collection('gastos')
                                      .add({
                                        'nome': nomeGasto,
                                        'valor': valorGasto,
                                        'categoria': _categoriaSelecionada,
                                        'iconeCategoria':
                                            iconeSelecionadoCodePoint, // Agora salva também o icone correto
                                        'divididoEntre':
                                            participantesSelecionados,
                                        'data': Timestamp.fromDate(
                                          _dataSelecionada!,
                                        ),
                                        'criadoEm':
                                            FieldValue.serverTimestamp(),
                                      });

                                  setState(() => _isLoading = false);

                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },

                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Salvar Gasto'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editarGasto(String gastoId) async {
    // Aqui você pode abrir uma nova tela ou mostrar um diálogo de edição
    // (por enquanto vamos só mostrar um alerta para ilustrar)

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Editar Gasto'),
            content: const Text('Funcionalidade de edição em desenvolvimento!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  void _excluirGasto(String gastoId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Excluir Gasto'),
            content: const Text('Tem certeza que deseja excluir este gasto?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      await FirebaseFirestore.instance
          .collection('grupos')
          .doc(widget.grupoId)
          .collection('gastos')
          .doc(gastoId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto excluído com sucesso!')),
      );
    }
  }

  Widget _buildAdicionarMembroTab() {
    return Column(
      children: [
        TabBar(
          controller: _innerTabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Membros do Grupo'), // <- NOVA ABA
            Tab(text: 'Buscar Usuário'),
            Tab(text: 'Convidar por E-mail'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _innerTabController,
            children: [
              _buildBuscarUsuarioTab(),
              _buildMembrosTab(), // <- NOVA FUNÇÃO
              _buildConvidarEmailTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembrosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final usuarios =
              snapshot.data!.docs
                  .where((doc) => _participantes.contains(doc.id))
                  .toList();

          if (usuarios.isEmpty) {
            return const Center(child: Text('Nenhum membro no grupo.'));
          }

          return Column(
            children:
                usuarios.map((usuario) {
                  final nome = usuario['nome'] ?? '';
                  final email = usuario['email'] ?? '';
                  final avatarUrl = usuario['avatarUrl'];

                  return ListTile(
                    leading:
                        avatarUrl != null
                            ? CircleAvatar(
                              backgroundImage: NetworkImage(avatarUrl),
                            )
                            : CircleAvatar(
                              child: Text(nome.isNotEmpty ? nome[0] : '?'),
                            ),
                    title: Text(nome),
                    subtitle: Text(email),
                  );
                }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildBuscarUsuarioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _buscaController,
            decoration: InputDecoration(
              hintText: 'Nome ou e-mail',
              prefixIcon: const Icon(Icons.search),
              fillColor: Colors.grey.shade100,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream:
                _buscaController.text.length > 2
                    ? FirebaseFirestore.instance
                        .collection('usuarios')
                        .where(
                          'nome',
                          isGreaterThanOrEqualTo: _buscaController.text.trim(),
                        )
                        .where(
                          'nome',
                          isLessThanOrEqualTo:
                              _buscaController.text.trim() + '\uf8ff',
                        )
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('usuarios')
                        .orderBy('criadoEm', descending: true)
                        .limit(10)
                        .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final usuarios = snapshot.data!.docs;
              if (usuarios.isEmpty)
                return const Text('Nenhum usuário encontrado.');

              return Column(
                children:
                    usuarios.map((usuario) {
                      final id = usuario.id;
                      final nome = usuario['nome'] ?? '';
                      final email = usuario['email'] ?? '';
                      final avatarUrl = usuario['avatarUrl'];
                      final jaEstaNoGrupo = _participantes.contains(id);

                      return ListTile(
                        leading:
                            avatarUrl != null
                                ? CircleAvatar(
                                  backgroundImage: NetworkImage(avatarUrl),
                                )
                                : CircleAvatar(
                                  child: Text(nome.isNotEmpty ? nome[0] : '?'),
                                ),
                        title: Text(nome),
                        subtitle: Text(email),
                        trailing:
                            jaEstaNoGrupo
                                ? const Text(
                                  'Já no grupo',
                                  style: TextStyle(color: Colors.grey),
                                )
                                : SizedBox(
                                  width: 70,
                                  height: 36,
                                  child: ElevatedButton(
                                    onPressed: () => _adicionarUsuario(id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Add',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConvidarEmailTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('E-mail'),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'Digite o e-mail',
              prefixIcon: const Icon(Icons.email),
              fillColor: Colors.grey.shade100,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _enviarConvite,
              child: const Text('Enviar Convite'),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Convites enviados',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('convites')
                    .where('grupoId', isEqualTo: widget.grupoId)
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final convites = snapshot.data!.docs;
              if (convites.isEmpty)
                return const Text('Nenhum convite enviado.');

              return Column(
                children:
                    convites.map((convite) {
                      final email = convite['email'] ?? '';
                      final status = convite['status'] ?? 'pendente';
                      return ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: Text(email),
                        subtitle: Text('Status: $status'),
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
