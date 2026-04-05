import Foundation

enum APIEndpoint {
    // Auth
    case appleAuth
    case getMe

    // Projects
    case listProjects
    case createProject
    case getProject(id: String)
    case updateProject(id: String)
    case deleteProject(id: String)

    // Generation
    case generateCalendar(projectID: String)
    case regenerateMonth(projectID: String, month: Int)
    case getJob(id: String)

    // Uploads
    case presignUpload

    // Tokens
    case getTokenBalance
    case getTokenHistory
    case getTokenProducts
    case verifyPurchase

    // Orders
    case submitPrintOrder(projectID: String)
    case exportPDF(projectID: String)
    case getOrder(id: String)

    var path: String {
        switch self {
        case .appleAuth:                         return "/api/v1/auth/apple"
        case .getMe:                             return "/api/v1/users/me"
        case .listProjects:                      return "/api/v1/projects"
        case .createProject:                     return "/api/v1/projects"
        case .getProject(let id):                return "/api/v1/projects/\(id)"
        case .updateProject(let id):             return "/api/v1/projects/\(id)"
        case .deleteProject(let id):             return "/api/v1/projects/\(id)"
        case .generateCalendar(let id):          return "/api/v1/projects/\(id)/generate"
        case .regenerateMonth(let id, let m):    return "/api/v1/projects/\(id)/months/\(m)/regenerate"
        case .getJob(let id):                    return "/api/v1/jobs/\(id)"
        case .presignUpload:                     return "/api/v1/uploads/presign"
        case .getTokenBalance:                   return "/api/v1/tokens/balance"
        case .getTokenHistory:                   return "/api/v1/tokens/history"
        case .getTokenProducts:                  return "/api/v1/tokens/products"
        case .verifyPurchase:                    return "/api/v1/tokens/verify-purchase"
        case .submitPrintOrder(let id):          return "/api/v1/projects/\(id)/orders/print"
        case .exportPDF(let id):                 return "/api/v1/projects/\(id)/orders/pdf-export"
        case .getOrder(let id):                  return "/api/v1/orders/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getMe, .listProjects, .getProject, .getJob,
             .getTokenBalance, .getTokenHistory, .getTokenProducts, .getOrder:
            return .GET
        case .deleteProject:
            return .DELETE
        case .updateProject:
            return .PATCH
        default:
            return .POST
        }
    }
}
