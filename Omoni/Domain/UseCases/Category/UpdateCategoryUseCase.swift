import Foundation

protocol UpdateCategoryUseCase {
    func execute(
        categoryId: UUID,
        name: String?,
        icon: String?,
        color: String?,
        limit: Decimal?,
        limitFrequency: String?
    ) async throws
}

final class DefaultUpdateCategoryUseCase: UpdateCategoryUseCase {
    private let categoryRepository: CategoryRepository

    init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    func execute(
        categoryId: UUID,
        name: String?,
        icon: String?,
        color: String?,
        limit: Decimal?,
        limitFrequency: String?
    ) async throws {
        guard let category = try await categoryRepository.fetchCategory(id: categoryId) else {
            throw RepositoryError.notFound
        }
        category.applyEdits(
            name: name ?? category.name,
            color: color ?? category.color,
            icon: icon ?? category.icon,
            limit: limit.map { Double(truncating: $0 as NSDecimalNumber) } ?? category.limit,
            limitFrequency: limitFrequency ?? category.limitFrequency
        )
        try await categoryRepository.updateCategory(category)
    }
}
