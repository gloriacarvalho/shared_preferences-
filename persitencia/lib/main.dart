
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ListaTarefasApp());
}

const Color verde = Color(0xFF2F6B5B);
const Color fundo = Color(0xFFF5F7F5);
const String chaveTarefas = 'lista_de_tarefas';

class Tarefa {
  final String titulo;
  final bool concluida;

  const Tarefa({
    required this.titulo,
    this.concluida = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'concluida': concluida,
    };
  }

  factory Tarefa.fromJson(Map<String, dynamic> json) {
    return Tarefa(
      titulo: json['titulo'] as String,
      concluida: json['concluida'] as bool? ?? false,
    );
  }
}

class ListaTarefasApp extends StatelessWidget {
  const ListaTarefasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Minha Lista',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: fundo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: verde,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: fundo,
          foregroundColor: Color(0xFF24352E),
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const TelaTarefas(),
    );
  }
}

class TelaTarefas extends StatefulWidget {
  const TelaTarefas({super.key});

  @override
  State<TelaTarefas> createState() => _TelaTarefasState();
}

class _TelaTarefasState extends State<TelaTarefas> {
  final TextEditingController _controller = TextEditingController();

  List<Tarefa> _tarefas = [];
  bool _carregando = true;

  int get _pendentes =>
      _tarefas.where((tarefa) => !tarefa.concluida).length;

  int get _concluidas =>
      _tarefas.where((tarefa) => tarefa.concluida).length;

  @override
  void initState() {
    super.initState();
    _carregarTarefas();
  }

  Future<void> _carregarTarefas() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      final dados = preferencias.getString(chaveTarefas);

      List<Tarefa> tarefasCarregadas = [];

      if (dados != null) {
        final lista = jsonDecode(dados) as List<dynamic>;

        tarefasCarregadas = lista.map((item) {
          return Tarefa.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
        }).toList();
      }

      if (!mounted) return;

      setState(() {
        _tarefas = tarefasCarregadas;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar as tarefas.'),
        ),
      );
    }
  }

  Future<void> _salvarTarefas() async {
    final preferencias = await SharedPreferences.getInstance();

    final dados = jsonEncode(
      _tarefas.map((tarefa) => tarefa.toJson()).toList(),
    );

    await preferencias.setString(chaveTarefas, dados);
  }

  Future<void> _adicionarTarefa() async {
    final titulo = _controller.text.trim();

    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o título da tarefa.'),
        ),
      );
      return;
    }

    setState(() {
      _tarefas.add(Tarefa(titulo: titulo));
      _controller.clear();
    });

    await _salvarTarefas();
  }

  Future<void> _alternarConclusao(int indice, bool? valor) async {
    if (valor == null) return;

    setState(() {
      final tarefa = _tarefas[indice];

      _tarefas[indice] = Tarefa(
        titulo: tarefa.titulo,
        concluida: valor,
      );
    });

    await _salvarTarefas();
  }

  Future<void> _excluirTarefa(int indice) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir tarefa?'),
        content: Text(
          'Deseja realmente excluir "${_tarefas[indice].titulo}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() {
      _tarefas.removeAt(indice);
    });

    await _salvarTarefas();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minha Lista',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Icon(
              Icons.check_circle_outline,
              color: verde,
              size: 28,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Organize seu dia.',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF24352E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Uma tarefa de cada vez.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: _CartaoResumo(
                                titulo: 'Pendentes',
                                quantidade: _pendentes,
                                icone: Icons.pending_actions,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CartaoResumo(
                                titulo: 'Concluídas',
                                quantidade: _concluidas,
                                icone: Icons.task_alt,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Nova tarefa',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _adicionarTarefa(),
                                decoration: const InputDecoration(
                                  hintText: 'O que você precisa fazer?',
                                  prefixIcon: Icon(Icons.edit_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 54,
                              width: 54,
                              child: FilledButton(
                                onPressed: _adicionarTarefa,
                                style: FilledButton.styleFrom(
                                  backgroundColor: verde,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Icon(Icons.add, size: 27),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        const Text(
                          'Suas tarefas',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF24352E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _tarefas.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.checklist_rounded,
                                    size: 62,
                                    color: verde.withValues(alpha: 0.55),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Tudo começa com uma tarefa.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Adicione sua primeira tarefa acima.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: _tarefas.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, indice) {
                              final tarefa = _tarefas[indice];

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE7ECE8),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  leading: Checkbox(
                                    value: tarefa.concluida,
                                    activeColor: verde,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    onChanged: (valor) =>
                                        _alternarConclusao(indice, valor),
                                  ),
                                  title: Text(
                                    tarefa.titulo,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      decoration: tarefa.concluida
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      color: tarefa.concluida
                                          ? Colors.grey
                                          : const Color(0xFF24352E),
                                    ),
                                  ),
                                  trailing: IconButton(
                                    tooltip: 'Excluir tarefa',
                                    onPressed: () =>
                                        _excluirTarefa(indice),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CartaoResumo extends StatelessWidget {
  final String titulo;
  final int quantidade;
  final IconData icone;

  const _CartaoResumo({
    required this.titulo,
    required this.quantidade,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: verde, size: 25),
          const SizedBox(height: 12),
          Text(
            '$quantidade',
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: Color(0xFF24352E),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
