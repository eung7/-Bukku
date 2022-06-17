//
//  BookListCell.swift
//  Bukku
//
//  Created by 김응철 on 2022/05/31.
//

import UIKit
import SnapKit
import Kingfisher

class BookListCell: UICollectionViewCell {
    // MARK: - Properties
    static let identifier = "BookListCell"
    var bookListVM: BookListViewModel?

    let thumbnailImage: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .getBlack()
        iv.layer.borderWidth = 0.5
        
        return iv
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .getBlack()
        label.font = .systemFont(ofSize: 24.0, weight: .bold)
        label.numberOfLines = 0
        
        return label
    }()
    
    let authorsLabel: UILabel = {
        let label = UILabel()
        label.textColor = .getBlack()
        label.font = .systemFont(ofSize: 16.0, weight: .light)
        
        return label
    }()
    
    let contentsLabel: UILabel = {
        let label = UILabel()
        label.textColor = .getBlack()
        label.font = .systemFont(ofSize: 14.0, weight: .medium)
        label.numberOfLines = 0
        
        return label
    }()
    
    let publisherLabel: UILabel = {
        let label = UILabel()
        label.textColor = .getBlack()
        label.font = .systemFont(ofSize: 14.0, weight: .ultraLight)
        
        return label
    }()
    
    // MARK: - Life Cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helpers
    func configureData() {
        guard let bookListVM = bookListVM else { return }
        if bookListVM.thumbnailURL == "" {
            thumbnailImage.image = UIImage(systemName: "xmark.octagon")
            return
        }
        thumbnailImage.kf.setImage(with: URL(string: bookListVM.thumbnailURL))
        titleLabel.text = bookListVM.title
        authorsLabel.text = bookListVM.author
        contentsLabel.text = bookListVM.contents
        publisherLabel.text = bookListVM.publisher
    }
    
    func configureUI() {
        contentView.backgroundColor = .getWhite()
        
        let verticalStack = UIStackView(arrangedSubviews: [ titleLabel, authorsLabel, publisherLabel ])
        verticalStack.axis = .vertical
        verticalStack.spacing = 4
        verticalStack.alignment = .leading
        
        [ thumbnailImage, verticalStack ]
            .forEach { contentView.addSubview($0) }
        
        thumbnailImage.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(8)
            make.width.equalTo(120); make.height.equalTo(174)
        }
        
        verticalStack.snp.makeConstraints { make in
            make.leading.equalTo(thumbnailImage.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(4)
            make.centerY.equalToSuperview()
        }
    }
}

