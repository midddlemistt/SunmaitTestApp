import SwiftUI

// MARK: - Push Navigation View
struct PushNavigationView: View {
    let block: NavigationBlock
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Text(block.title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color("AppBlack"))
            
            if let subtitle = block.subtitle {
                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color("AppGrey"))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBeige"))
        .navigationTitle(block.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Modal Navigation View
struct ModalNavigationView: View {
    let block: NavigationBlock
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Grabber
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            // Close button
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color("AppBlue"))
                }
                .padding(.leading, 16)
                .padding(.top, 11)
                
                Spacer()
            }
            
            Spacer()
            
            // Content
            VStack(spacing: 8) {
                if let symbol = block.titleSymbol {
                    Image(systemName: symbol)
                        .font(.system(size: 40))
                        .foregroundStyle(Color("AppBlue"))
                }
                
                Text(block.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color("AppBlack"))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBeige"))
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Full Screen Navigation View
struct FullScreenNavigationView: View {
    let block: NavigationBlock
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color("AppBlue"))
                }
                .padding(.leading, 16)
                .padding(.top, 16)
                
                Spacer()
            }
            
            Spacer()
            
            // Content
            VStack(spacing: 8) {
                Text(block.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color("AppBlack"))
                    .multilineTextAlignment(.center)
                
                if let subtitle = block.subtitle {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color("AppGrey"))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBeige"))
    }
}

#Preview("Push") {
    NavigationStack {
        PushNavigationView(
            block: NavigationBlock(
                id: 1,
                title: "All News in One Place",
                subtitle: "Stay informed quickly\nand conveniently",
                titleSymbol: nil,
                buttonTitle: "Go",
                buttonSymbol: "arrow.right",
                navigation: .push
            )
        )
    }
}

#Preview("Modal") {
    ModalNavigationView(
        block: NavigationBlock(
            id: 2,
            title: "Be First to Know What Matters",
            subtitle: nil,
            titleSymbol: "star.circle.fill",
            buttonTitle: "Start Reading",
            buttonSymbol: "arrow.up.right",
            navigation: .modal
        )
    )
}

#Preview("FullScreen") {
    FullScreenNavigationView(
        block: NavigationBlock(
            id: 3,
            title: "Read. Learn. Share.",
            subtitle: "Only fresh and verified news",
            titleSymbol: nil,
            buttonTitle: "Try Premium",
            buttonSymbol: nil,
            navigation: .fullScreen
        )
    )
}
