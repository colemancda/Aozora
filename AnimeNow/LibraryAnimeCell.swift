//
//  LibraryAnimeCell.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/2/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import ANParseKit
import ANCommonKit
import Bolts

protocol LibraryAnimeCellDelegate: class {
    func cellPressedWatched(cell: LibraryAnimeCell, anime: Anime)
    func cellPressedEpisodeThread(cell: LibraryAnimeCell, anime: Anime, episode: Episode)
}
class LibraryAnimeCell: AnimeCell {
    
    weak var delegate: LibraryAnimeCellDelegate?
    var anime: Anime?
    weak var episode: Episode?
    var currentCancellationToken: NSOperation?
    
    @IBOutlet weak var userProgressLabel: UILabel!
    @IBOutlet weak var watchedButton: UIButton?
    @IBOutlet weak var commentButton: UIButton?
    @IBOutlet weak var episodeImageView: UIImageView?
    
    @IBAction func watchedPressed(sender: AnyObject) {
        
        if let anime = anime, let progress = anime.progress ?? anime.publicProgress {
            
            progress.watchedEpisodes += 1
            progress.updatedEpisodes(anime.episodes)
            progress.saveInBackground()
            LibrarySyncController.updateAnime(progress)
        }
        
        delegate?.cellPressedWatched(self, anime:anime!)
        watchedButton?.animateBounce()
    }
    
    override func configureWithAnime(
        anime: Anime,
        canFadeImages: Bool = true,
        showEtaAsAired: Bool = false,
        showLibraryEta: Bool = false,
        publicAnime: Bool = false) {
        
            super.configureWithAnime(anime, canFadeImages: canFadeImages, showEtaAsAired: showEtaAsAired, showLibraryEta: showLibraryEta, publicAnime: publicAnime)
        
            self.anime = anime
        
            if let progress = publicAnime ? anime.publicProgress : anime.progress {
            
            watchedButton?.enabled = true
            let title = FontAwesome.Watched.rawValue
            watchedButton?.setTitle(title, forState: UIControlState.Normal)
            
            userProgressLabel.text = "\(anime.type) · " + FontAwesome.Watched.rawValue + " \(progress.watchedEpisodes)/\(anime.episodes)   " + FontAwesome.Rated.rawValue + " \(progress.score)"
            
            if let episodeImageView = episodeImageView {
                if progress.myAnimeListList() == .Watching {
                    setEpisodeImageView(anime, nextEpisode: progress.watchedEpisodes)
                } else {
                    episodeImageView.setImageFrom(urlString: anime.fanartThumbURLString() ?? "")
                }
            }
            
            if progress.myAnimeListList() == .Completed || progress.myAnimeListList() == .Dropped || (progress.watchedEpisodes == anime.episodes && anime.episodes != 0) {
                watchedButton?.enabled = false
            }
        }
    }
    
    func setEpisodeImageView(anime: Anime, nextEpisode: Int?) {
        
        if let cancelToken = currentCancellationToken {
            cancelToken.cancel()
        }
        
        let newCancelationToken = NSOperation()
        currentCancellationToken = newCancelationToken
        
        episodeImageView?.image = nil
        episode = nil
        anime.episodeList().continueWithExecutor(BFExecutor.mainThreadExecutor(), withSuccessBlock: { (task: BFTask!) -> AnyObject! in
            
            if newCancelationToken.cancelled {
                return nil
            }
            
            guard let episodes = task.result as? [Episode],
                let nextEpisode = nextEpisode where episodes.count > nextEpisode else {
                    self.episodeImageView?.setImageFrom(urlString: anime.fanart ?? anime.imageUrl ?? "")
                    return nil
            }
            
            let episode = episodes[nextEpisode]
            self.episode = episode
            self.episodeImageView?.setImageFrom(urlString: episode.imageURLString())
            
            return nil
        })
    }
    
    // MARK: - IBActions
    
    @IBAction func pressedEpisodeImageView(sender: AnyObject) {
        if let episode = episode {
            delegate?.cellPressedEpisodeThread(self, anime: episode.anime, episode: episode)
        }
    }

}