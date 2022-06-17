//
//  SearchViewController.swift
//  Bukku
//
//  Created by 김응철 on 2022/05/31.
//

import UIKit
import SnapKit
import PanModal

// TODO: [] 새로운 검색을 할 때 최상단으로 포커스 가기

class SearchViewController: UIViewController {
    // MARK: - States
    var currentPage: Int = 1
    var currentQuery: String = ""
    var isLoading: Bool = true
    var loadingFooterView: LoadingFooterView?
    
    // MARK: - Properties
    let viewModel = SearchViewModel()
    
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar(
            frame: CGRect(x: 0, y: 0,
            width: UIScreen.main.bounds.width - 75,
            height: 0)
        )
        searchBar.placeholder = "책 이름을 알려주세요!"
        searchBar.returnKeyType = .search
        searchBar.searchTextField.leftView?.tintColor = .getBlack()
        searchBar.delegate = self

        return searchBar
    }()
    
    lazy var cameraTabBarItem: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "camera.viewfinder"), for: .normal)
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration.init(pointSize: 24.0), forImageIn: .normal)
        button.addTarget(self, action: #selector(didTapCameraButton), for: .touchUpInside)
        button.tintColor = .getBlack()
        
        return button
    }()
    
    lazy var bookListCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .getGray()
        collectionView.register(BookListCell.self, forCellWithReuseIdentifier: BookListCell.identifier)
        collectionView.register(
            LoadingFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: LoadingFooterView.identifier
        )
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        
        return collectionView
    }()
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    // MARK: - Selectors
    @objc func didTapCameraButton() {
        
    }
    
    // MARK: - Helpers
    func configureUI() {
        view.backgroundColor = .getGray()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: searchBar)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cameraTabBarItem)
        
        bookListCollectionView.isHidden = true
        
        [ bookListCollectionView ]
            .forEach { view.addSubview($0) }
        
        bookListCollectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if bookListCollectionView.contentOffset.y > (bookListCollectionView.contentSize.height - bookListCollectionView.bounds.size.height) {
            if !isLoading {
                isLoading = true
                bookListCollectionView.reloadData()
                SearchService.fetchBooks(currentQuery, page: currentPage) { [weak self] response, updatedPage in
                    if response.meta.is_end == false {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                            self?.viewModel.books.append(contentsOf: response.documents)
                            self?.bookListCollectionView.reloadData()
                            self?.isLoading = false
                            self?.currentPage = updatedPage
                        })
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.isLoading = false
                            self?.bookListCollectionView.reloadData()
                        }
                        return
                    }
                }
            }
        }
    }
}

// MARK: - SearchBar Methods
extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.searchTextField.resignFirstResponder()
        guard let query = searchBar.searchTextField.text else { return }
        self.currentQuery = query
        SearchService.fetchBooks(query, page: 1) { [weak self] response, currentPage in
            self?.viewModel.books = response.documents
            self?.currentPage = currentPage
            self?.isLoading = false
            self?.bookListCollectionView.reloadData()
            self?.bookListCollectionView.contentOffset.y = 0
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        bookListCollectionView.isHidden = false
        isLoading = false
        bookListCollectionView.reloadData()
        return true
    }
}

// MARK: - BookListCollectionViewDataSource
extension SearchViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.books.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: BookListCell.identifier,
            for: indexPath
        ) as? BookListCell else { return UICollectionViewCell() }
        let book = viewModel.books[indexPath.row]
        cell.bookListVM = BookListViewModel(book: book)
        cell.configureData()

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            guard let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionFooter,
                withReuseIdentifier: LoadingFooterView.identifier,
                for: indexPath
            ) as? LoadingFooterView else { return UICollectionReusableView() }
            self.loadingFooterView = footer
            
            return footer
        } else {
            return UICollectionReusableView()
        }
    }
}

// MARK: - BookListCollectionViewDelegateFlowLayout
extension SearchViewController: UICollectionViewDelegateFlowLayout {
    /// Cell Did Select
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let bookListVM = viewModel.getBookFromIndex(indexPath.row)
        let bookDetailVC = BookDetailViewController(bookListVM: bookListVM)
        presentPanModal(bookDetailVC)
    }
    
    /// Cell Size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 180)
    }
    
    /// Footer Size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if isLoading {
            return CGSize(width: UIScreen.main.bounds.width, height: 50)
        } else {
            return CGSize.zero
        }
    }

    /// CollectionView Item Spacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    /// CollectionView Insets
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionFooter {
            if isLoading {
                loadingFooterView?.indicator.startAnimating()
            } else {
                loadingFooterView?.indicator.stopAnimating()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionFooter {
            loadingFooterView?.indicator.stopAnimating()
        }
    }
}
