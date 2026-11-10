import Foundation

class ModelRouter { init() {} }

struct ModelInfo { var id: UUID = UUID(); var name: String; var size: UInt64 = 0 }

enum RoutingStrategy: String { case local, remote, hybrid }