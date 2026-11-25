// url=https://www.figma.com/design/cr2WrAfZEm0KTQvmYRL3w4/Untitled?node-id=0:1
// source=lib/core/widgets/primary_button.dart
// component=PrimaryButton
import figma from 'figma'

const instance = figma.selectedInstance

const label = instance.getString('Label')
const isLoading = instance.getBoolean('Loading')
const disabled = instance.getBoolean('Disabled')
const variant = instance.getEnum('Variant', {
  'Primary': 'PrimaryButton',
  'Secondary': 'SecondaryButton',
})

const icon = instance.getInstanceSwap('Icon')
let iconCode: any
if (icon && icon.type === 'INSTANCE') {
  iconCode = icon.executeTemplate().example
}

const componentName = variant || 'PrimaryButton'

export default {
  example: figma.code`${componentName}(
  label: '${label}',
  onPressed: ${disabled ? 'null' : '() {\n    // Aksi tombol\n  }'},
  ${isLoading ? 'isLoading: true,\n  ' : ''}${iconCode ? figma.code`icon: ${iconCode},\n  ` : ''}
)`,
  imports: [
    `import 'package:motocare/core/widgets/${componentName === 'SecondaryButton' ? 'secondary_button' : 'primary_button'}.dart';`,
  ],
  id: 'primary-button',
  metadata: {
    nestable: true,
  },
}
