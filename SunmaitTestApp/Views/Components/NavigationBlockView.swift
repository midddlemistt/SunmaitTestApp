import SwiftUI

struct NavigationBlockView: View {
    let block: NavigationBlock
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon and Title
            if let symbol = block.titleSymbol {
                HStack {
                    Spacer()
                    Image(systemName: symbol)
                        .font(.system(size: 20))
                        .foregroundStyle(.appBlue)
                    Spacer()
                }
            }
            
            // Title
            Text(block.title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.appBlack)
                .multilineTextAlignment(block.titleSymbol != nil ? .center : .leading)
                .frame(maxWidth: .infinity, alignment: block.titleSymbol != nil ? .center : .leading)
            
            // Subtitle
            if let subtitle = block.subtitle {
                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.appGrey)
                    .multilineTextAlignment(block.titleSymbol != nil ? .center : .leading)
                    .frame(maxWidth: .infinity, alignment: block.titleSymbol != nil ? .center : .leading)
            }
            
            Spacer(minLength: 8)
            
            // Button
            Button(action: onTap) {
                HStack(spacing: 8) {
                    Text(block.buttonTitle)
                        .font(.system(size: 17, weight: .bold))
                    
                    if let buttonSymbol = block.buttonSymbol {
                        Image(systemName: buttonSymbol)
                            .font(.system(size: 20))
                    }
                }
                .foregroundStyle(.appWhite)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(.appBlue)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(16)
        .frame(height: 144)
        .background(.appWhite)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    VStack(spacing: 16) {
        NavigationBlockView(
            block: NavigationBlock(
                id: 1,
                title: "All News in One Place",
                subtitle: "Stay informed quickly\nand conveniently",
                titleSymbol: nil,
                buttonTitle: "Go",
                buttonSymbol: "arrow.right",
                navigation: .push
            ),
            onTap: {}
        )
        
        NavigationBlockView(
            block: NavigationBlock(
                id: 2,
                title: "Be First to Know What Matters",
                subtitle: nil,
                titleSymbol: "star.circle.fill",
                buttonTitle: "Start Reading",
                buttonSymbol: "arrow.up.right",
                navigation: .modal
            ),
            onTap: {}
        )
    }
    .padding()
    .background(.appBeige)
}

