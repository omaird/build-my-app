---
name: translate-component
description: Convert a single React component to SwiftUI
allowed_tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
arguments:
  - name: source
    description: Path to the React component file to translate
    required: true
  - name: destination
    description: Path for the output SwiftUI file (optional, defaults to same name in iOS project)
    required: false
---

# Translate React Component to SwiftUI

Convert a React/TypeScript component from the RIZQ web app to a native SwiftUI view.

## Translation Process

1. **Read the source component** at `{{ source }}`

2. **Analyze the component**:
   - Extract props interface
   - Identify useState hooks → @State
   - Find useEffect hooks → .onAppear/.task/.onChange
   - Map Tailwind classes → SwiftUI modifiers
   - Convert Framer Motion → SwiftUI animations

3. **Apply RIZQ design system**:
   - Use .rizqPrimary, .rizqBackground colors
   - Apply .font(.rizqDisplay(...)) typography
   - Use RIZQSpacing constants
   - Add .rizqCard() and .rizqShadowSoft() modifiers

4. **Generate SwiftUI code**:
   - Create View struct with proper naming
   - Add parameters for props
   - Include @State for local state
   - Add preview at bottom

## Example Input/Output

**React Input:**
```typescript
interface CardProps {
  title: string;
  isActive?: boolean;
  onTap?: () => void;
}

export function Card({ title, isActive = false, onTap }: CardProps) {
  const [expanded, setExpanded] = useState(false);

  return (
    <motion.div
      className="p-4 rounded-islamic bg-card"
      whileTap={{ scale: 0.98 }}
      onClick={onTap}
    >
      <h3 className="font-display text-lg">{title}</h3>
    </motion.div>
  );
}
```

**SwiftUI Output:**
```swift
import SwiftUI

struct Card: View {
  let title: String
  var isActive: Bool = false
  var onTap: (() -> Void)? = nil

  @State private var expanded = false

  var body: some View {
    Button(action: { onTap?() }) {
      Text(title)
        .font(.rizqDisplay(.title3))
    }
    .padding(RIZQSpacing.md)
    .background(.rizqCard)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .buttonStyle(ScaleButtonStyle())
  }
}

#Preview {
  Card(title: "Example", isActive: true)
}
```

## Reference Skills

- component-translator agent
- swiftui-patterns skill
- design-system-ios skill
- animation-mapping skill
