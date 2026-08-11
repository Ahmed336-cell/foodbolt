import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/numeric_input.dart';
import '../cubit/receipt_cubit.dart';

class ReceiptUploadScreen extends StatelessWidget {
  const ReceiptUploadScreen({super.key});

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file != null && context.mounted) {
      context.read<ReceiptCubit>().setImage(file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.uploadReceiptTitle)),
      body: BlocBuilder<ReceiptCubit, ReceiptState>(
        builder: (context, state) {
          return AdaptivePadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionPrompt(text: l10n.uploadReceiptPrompt),
                const SizedBox(height: 16),
                if (state.error != null) ErrorBanner(message: state.error!),
                if (state.success) Text(l10n.receiptUploaded),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black12, width: 2),
                    ),
                    child: state.localPath == null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🧾', style: TextStyle(fontSize: 44)),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.receiptFrameHint,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                state.localPath!,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: NumericInput.decimalKeyboard,
                  inputFormatters: NumericInput.decimal,
                  decoration: InputDecoration(hintText: l10n.receiptTotalHint),
                  onChanged: context.read<ReceiptCubit>().setTotal,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: l10n.camera,
                        onPressed: () => _pick(context, ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SecondaryButton(
                        label: l10n.gallery,
                        onPressed: () => _pick(context, ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                if (state.localPath != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.read<ReceiptCubit>().clearImage(),
                    child: Text(l10n.retake),
                  ),
                ],
                const SizedBox(height: 8),
                PrimaryButton(
                  label: l10n.upload,
                  loading: state.loading,
                  onPressed: () => context.read<ReceiptCubit>().upload(),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: state.loading
                      ? null
                      : () => context.read<ReceiptCubit>().skip(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.primary, width: 1.4),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.skipReceipt,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        l10n.skipReceiptHint,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
