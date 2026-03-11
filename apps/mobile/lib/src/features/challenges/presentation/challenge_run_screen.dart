part of '../../../../main.dart';

class ChallengeRunScreen extends StatefulWidget {
  const ChallengeRunScreen({
    super.key,
    required this.api,
    required this.session,
    required this.challenge,
  });

  final ApiClient api;
  final AuthSession session;
  final ChallengeModel challenge;

  @override
  State<ChallengeRunScreen> createState() => _ChallengeRunScreenState();
}

class _ChallengeRunScreenState extends State<ChallengeRunScreen> {
  final OfflineAppController _offline = OfflineAppController.instance;
  SubmissionModel? _submission;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreExistingSubmission();
  }

  Future<void> _restoreExistingSubmission() async {
    try {
      final submission = await _offline.loadOrCreateSubmission(
        widget.challenge,
      );
      if (!mounted) return;
      setState(() => _submission = submission);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _captureAndUpload(ChallengeItem item) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await Navigator.of(context).push<File>(
        MaterialPageRoute(
          builder: (_) => CameraCaptureScreen(itemLabel: item.label),
        ),
      );
      if (file == null) return;
      final submission = await _offline.captureEvidence(
        challenge: widget.challenge,
        item: item,
        sourceFile: file,
      );
      if (!mounted) return;
      setState(() => _submission = submission);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeAndGeneratePdf() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar reto'),
        content: const Text(
          'Se guardará localmente y se sincronizará al reconectar si no hay internet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final submission = await _offline.completeSubmission(widget.challenge);
      _submission = submission;
      final bytes = await PdfReportService.buildReport(
        challenge: widget.challenge,
        userName: widget.session.userName,
        userEmail: widget.session.userEmail,
        evidenceFiles: {
          for (final evidence in submission.evidences)
            if (evidence.localFilePath != null &&
                evidence.localFilePath!.isNotEmpty)
              evidence.itemCode: File(evidence.localFilePath!),
        },
      );
      final dir = await getTemporaryDirectory();
      final fileName =
          '${_pdfFilePrefix(widget.challenge.type)}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File(p.join(dir.path, fileName));
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      setState(() {});
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              PdfPreviewScreen(pdfBytes: bytes, filePath: file.path),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submission = _submission;
    final evidenceByCode = <String, SubmissionEvidenceModel>{
      for (final evidence
          in submission?.evidences ?? const <SubmissionEvidenceModel>[])
        evidence.itemCode: evidence,
    };
    final completedCount = widget.challenge.items
        .where((i) => evidenceByCode.containsKey(i.code))
        .length;
    final isComplete =
        completedCount == widget.challenge.items.length &&
        widget.challenge.items.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(widget.challenge.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FadeSlideIn(
            delay: const Duration(milliseconds: 40),
            child: SoftGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: widget.challenge.type
                              .color(context)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          widget.challenge.type.icon,
                          color: widget.challenge.type.color(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.challenge.type.challengeTypeLabel,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Text(
                              'Checklist de evidencias',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(999),
                    value: widget.challenge.items.isEmpty
                        ? 0
                        : completedCount / widget.challenge.items.length,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SummaryChip(
                        icon: Icons.task_alt,
                        label: 'completadas',
                        value:
                            '$completedCount/${widget.challenge.items.length}',
                      ),
                      SummaryChip(
                        icon: Icons.sync_outlined,
                        label: 'Estado',
                        value: submission == null
                            ? 'Preparando'
                            : submission.syncStatus.label,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...widget.challenge.items.asMap().entries.map((entry) {
            final item = entry.value;
            final itemIndex = entry.key;
            final evidence = evidenceByCode[item.code];
            final localPath = evidence?.localFilePath;
            final uploadedPath = evidence?.photoPath;
            final hasLocalPreview =
                localPath != null &&
                localPath.isNotEmpty &&
                File(localPath).existsSync();
            final hasRemotePreview =
                uploadedPath != null &&
                uploadedPath.isNotEmpty &&
                uploadedPath.startsWith('http');
            final isMissingLocalFile =
                localPath != null && localPath.isNotEmpty && !hasLocalPreview;
            final status = evidence?.syncStatus ?? SyncStatus.pending;
            final fileLabel = switch ((hasLocalPreview, hasRemotePreview)) {
              (true, _) => p.basename(localPath!),
              (false, true) => p.basename(uploadedPath!),
              _ when isMissingLocalFile => 'Archivo local no disponible',
              _ => 'Pendiente',
            };
            return FadeSlideIn(
              delay: Duration(milliseconds: 90 + (itemIndex * 35)),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        if (hasLocalPreview)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(localPath),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          )
                        else if (hasRemotePreview)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              uploadedPath,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.camera_alt_outlined),
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fileLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                evidence?.syncStatus.label ?? 'Pendiente',
                                style: TextStyle(
                                  color: switch (status) {
                                    SyncStatus.synced => Colors.green,
                                    SyncStatus.error => Colors.red,
                                    SyncStatus.syncing => Colors.blue,
                                    SyncStatus.pending => const Color(
                                      0xFFAD6A00,
                                    ),
                                  },
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              switch (status) {
                                SyncStatus.synced => Icons.check_circle,
                                SyncStatus.error => Icons.error_outline,
                                SyncStatus.syncing => Icons.sync,
                                SyncStatus.pending => Icons.schedule,
                              },
                              color: switch (status) {
                                SyncStatus.synced => Colors.green,
                                SyncStatus.error => Colors.red,
                                SyncStatus.syncing => Colors.blue,
                                SyncStatus.pending => const Color(0xFFAD6A00),
                              },
                            ),
                            const SizedBox(height: 6),
                            IconButton.filledTonal(
                              onPressed: _busy
                                  ? null
                                  : () => _captureAndUpload(item),
                              icon: const Icon(Icons.camera_alt),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          if (_error != null) ...[
            const SizedBox(height: 8),
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: InlineStatusCard(
                message: _error!,
                icon: Icons.error_outline,
                color: Colors.red,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: const Duration(milliseconds: 130),
            child: FilledButton.icon(
              onPressed: (_busy || !isComplete)
                  ? null
                  : _completeAndGeneratePdf,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(
                _busy
                    ? 'Procesando...'
                    : _offline.isOnline
                    ? 'Completar y generar PDF'
                    : 'Guardar offline y generar PDF',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
