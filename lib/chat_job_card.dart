import 'package:flutter/material.dart';

import 'estimate_fields.dart';
import 'job_summary.dart';
import 'ui.dart';

class ChatJobCard extends StatelessWidget {
  const ChatJobCard({
    super.key,
    required this.summary,
    required this.fromPost,
    required this.onEdit,
  });
  final JobSummary summary;
  final bool fromPost;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final title = summary.title.isEmpty ? 'Qual é o serviço?' : summary.title;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: InkColors.pale,
      child: InkWell(
        onTap: onEdit,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (MediaQuery.sizeOf(context).height - keyboard) * .32,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fromPost ? 'Pedido · $title' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: InkColors.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (keyboard == 0 && summary.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          summary.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: InkColors.muted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Estimativa · ${summary.priceLabel}',
                        style: const TextStyle(
                          color: InkColors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Editar serviço e propor valor',
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: InkColors.blue,
                    size: 21,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<JobSummary?> editChatJob(BuildContext context, JobSummary summary) =>
    showModalBottomSheet<JobSummary>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _JobEditor(summary: summary),
    );

class _JobEditor extends StatefulWidget {
  const _JobEditor({required this.summary});
  final JobSummary summary;
  @override
  State<_JobEditor> createState() => _JobEditorState();
}

class _JobEditorState extends State<_JobEditor> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.summary.title);
  late final _details = TextEditingController(text: widget.summary.description);
  late final _amount = TextEditingController(
    text: widget.summary.price?.amount ?? '',
  );
  late var _unit = widget.summary.price?.unit ?? PriceUnit.service;

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      JobSummary(
        _title.text.trim(),
        _details.text.trim(),
        Estimate.fromInput(_amount.text, _unit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Detalhes do serviço',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'A proposta fica no histórico desta conversa.',
                style: TextStyle(color: InkColors.muted),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _title,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Serviço',
                  counterText: '',
                ),
                validator: (text) => (text ?? '').trim().isEmpty
                    ? 'Dê um nome ao serviço.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _details,
                minLines: 2,
                maxLines: 5,
                maxLength: 1400,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  counterText: '',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              EstimateFields(
                amount: _amount,
                unit: _unit,
                onUnitChanged: (unit) => setState(() => _unit = unit),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submit,
                child: const Text('Enviar proposta'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
