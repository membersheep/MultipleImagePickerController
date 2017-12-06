//
//  MultipleImagePickerController.swift
//  DucatiLink
//
//  Created by Alessandro Maroso on 02/12/2017.
//  Copyright © 2017 Rawfish. All rights reserved.
//

import Foundation
import UIKit
import Photos

protocol MultipleImagePickerControllerDelegate {
    func multipleImage(picker: MultipleImagePickerController, didFinishPicking images: [UIImage])
    func multipleImagePickerDidCancel(picker: MultipleImagePickerController)
}

class MultipleImagePickerController: UIViewController, UIGestureRecognizerDelegate {
    
    private let cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(UIColor.red, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private let doneButton: UIButton = {
        let button = UIButton()
        button.setTitle("Done", for: .normal)
        button.setTitleColor(UIColor.red, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    fileprivate let imagesCollectionView: UICollectionView = {
        let collection = UICollectionView(frame: CGRect.zero, collectionViewLayout: MultipleImagePickerController.createCollectionViewLayout())
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.backgroundColor = UIColor.clear
        return collection
    }()
    fileprivate let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.activityIndicatorViewStyle = .whiteLarge
        indicator.color = UIColor.red
        return indicator
    }()
    
    fileprivate var photoFetchResult: PHFetchResult<PHAsset>?
    fileprivate var selectedIndices: IndexSet = IndexSet()

    var delegate: MultipleImagePickerControllerDelegate?
    
    // MARK: - Lifecycle

    init(delegate: MultipleImagePickerControllerDelegate? = nil) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupAppearance()
        self.addSubviews()
        self.setupConstraints()
        self.setupCollection()
        self.setupButtons()
    }
    
    // MARK: - Setup
    
    func setupAppearance(){
        self.view.backgroundColor = UIColor.white
    }
    
    func addSubviews() {
        self.view.addSubview(self.cancelButton)
        self.view.addSubview(self.doneButton)
        self.view.addSubview(self.imagesCollectionView)
        self.view.addSubview(self.activityIndicator)
    }
    
    func setupConstraints() {
        var margins: UILayoutGuide = view.layoutMarginsGuide
        if #available(iOS 11.0, *) {
            margins = view.safeAreaLayoutGuide
        }
        self.cancelButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 10).isActive = true
        self.cancelButton.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
        self.cancelButton.heightAnchor.constraint(equalToConstant: 40).isActive = true

        self.doneButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -10).isActive = true
        self.doneButton.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
        self.doneButton.heightAnchor.constraint(equalToConstant: 40).isActive = true

        self.imagesCollectionView.topAnchor.constraint(equalTo: self.cancelButton.bottomAnchor).isActive = true
        self.imagesCollectionView.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
        self.imagesCollectionView.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
        self.imagesCollectionView.bottomAnchor.constraint(equalTo: margins.bottomAnchor).isActive = true
        
        self.activityIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
    }
    
    func setupCollection() {
        self.imagesCollectionView.register(MultipleImagePickerCell.self, forCellWithReuseIdentifier: String(describing:MultipleImagePickerCell.self))
        self.imagesCollectionView.delegate = self
        self.imagesCollectionView.dataSource = self
        self.loadPhotos()
    }
    
    func setupButtons() {
        self.cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        self.doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
    }
    
    private func loadPhotos() {
        PHPhotoLibrary.requestAuthorization { [weak self] (status) in
            switch status {
            case .authorized:
                let fetchOptions = PHFetchOptions()
                self?.photoFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                DispatchQueue.main.async {
                    self?.imagesCollectionView.reloadData()
                }
            default:
                break
            }
        }
    }
    
    // MARK:- Actions
    
    @objc func cancelButtonTapped() {
        self.delegate?.multipleImagePickerDidCancel(picker: self)
    }

    @objc func doneButtonTapped() {
        guard let result = self.photoFetchResult else { return }
        self.activityIndicator.startAnimating()
        let dispatchGroup = DispatchGroup()
        let assets = result.objects(at: self.selectedIndices)
        var images = [UIImage]()
        for asset in assets {
            dispatchGroup.enter()
            PHImageManager.default().requestImageData(for: asset, options: nil, resultHandler: { (data, _, _, _) in
                guard let data = data, let image = UIImage(data: data) else { return }
                images.append(image)
                dispatchGroup.leave()
            })
        }
        dispatchGroup.notify(queue: DispatchQueue.main) {
            self.activityIndicator.stopAnimating()
            self.delegate?.multipleImage(picker: self, didFinishPicking: images)
        }
    }
    
    fileprivate func toggleItem(at indexPath: IndexPath) {
        if self.selectedIndices.contains(indexPath.row) {
            self.selectedIndices.remove(indexPath.row)
        } else {
            self.selectedIndices.insert(indexPath.row)
        }
        self.imagesCollectionView.reloadItems(at: [indexPath])
    }
    
    private static func createCollectionViewLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: 80, height: 80)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        layout.scrollDirection = .vertical
        return layout
    }
}

extension MultipleImagePickerController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let result = self.photoFetchResult else { return 0 }
        return result.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return self.imagesCollectionView.dequeueReusableCell(withReuseIdentifier: String(describing:MultipleImagePickerCell.self), for: indexPath)
    }
}

extension MultipleImagePickerController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let result = self.photoFetchResult else { return }
        let asset = result.object(at: indexPath.row)
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        PHImageManager.default().requestImage(for: asset, targetSize: MultipleImagePickerCell.cellSize, contentMode: .aspectFill, options: options) { [unowned self] (image, info) in
            guard let image = image, let cell = cell as? MultipleImagePickerCell else { return }
            cell.set(image: image, selected: self.selectedIndices.contains(indexPath.row))
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.toggleItem(at: indexPath)
    }
}

class MultipleImagePickerCell: UICollectionViewCell {
    
    static let cellSize = CGSize(width: 80, height: 80)
    static let hoverViewColor = UIColor(white: 15.0 / 255.0, alpha: 0.6)
    
    // MARK: - Properties
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    let hoverView: UIView = {
        let hoverView = UIView()
        hoverView.backgroundColor = MultipleImagePickerCell.hoverViewColor
        hoverView.translatesAutoresizingMaskIntoConstraints = false
        return hoverView
    }()
    let deleteImageView: UIImageView = {
        let deleteImageView = UIImageView(image: #imageLiteral(resourceName: "deletePhoto"))
        deleteImageView.contentMode = .scaleAspectFit
        deleteImageView.translatesAutoresizingMaskIntoConstraints = false
        return deleteImageView
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.addSubviews()
        self.setNeedsUpdateConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    func addSubviews() {
        self.addSubview(imageView)
        self.addSubview(hoverView)
        self.addSubview(deleteImageView)
    }
    
    override func updateConstraints() {
        self.imageView.removeConstraints(self.imageView.constraints)
        self.imageView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        self.imageView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        self.imageView.heightAnchor.constraint(equalToConstant: MultipleImagePickerCell.cellSize.height).isActive = true
        self.imageView.widthAnchor.constraint(equalToConstant: MultipleImagePickerCell.cellSize.width).isActive = true
        
        self.hoverView.removeConstraints(self.hoverView.constraints)
        self.hoverView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        self.hoverView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        self.hoverView.heightAnchor.constraint(equalToConstant: MultipleImagePickerCell.cellSize.height).isActive = true
        self.hoverView.widthAnchor.constraint(equalToConstant: MultipleImagePickerCell.cellSize.width).isActive = true
        
        self.deleteImageView.removeConstraints(self.deleteImageView.constraints)
        self.deleteImageView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        self.deleteImageView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        self.deleteImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        self.deleteImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        super.updateConstraints()
    }
    
    func set(image: UIImage, selected: Bool) {
        self.imageView.image = image
        self.hoverView.isHidden = !selected
        self.deleteImageView.isHidden = !selected
    }
}
