import SwiftUI

struct MessageListView: View { var body: some View { } }

struct MessageBubble: View { var body: some View { } }

struct Message: Identifiable { var id: UUID = UUID(); var role: String; var content: String }