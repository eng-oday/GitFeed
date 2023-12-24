

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

class ActivityController: UITableViewController {
  private let repo = "ReactiveX/RxSwift"

  private let events = BehaviorRelay<[Event]>(value: [])
  private let bag    = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = repo

    self.refreshControl = UIRefreshControl()
    let refreshControl = self.refreshControl!

    refreshControl.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
    refreshControl.tintColor = UIColor.darkGray
    refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
    refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)

    refresh()
  }

  @objc func refresh() {
    DispatchQueue.global(qos: .default).async { [weak self] in
      guard let self = self else { return }
      self.fetchEvents(repo: self.repo)
    }
  }

  func fetchEvents(repo: String) {
    let response = Observable.from([repo])
    
    // 1. ADD REPO NAME TO URL STRING AND CONVERT IT TO URL
      .map { urlString in
         return URL(string: "https://api.github.com/repos/\(urlString)/events")!
      }
    // 2. CONVERT URL TO URLREQUEST
      .map { finalUrl -> URLRequest in
        return URLRequest(url: finalUrl)
      }
    // 3. SEND REQUEST AND RETURN RESPONSE
      .flatMap { request -> Observable<(response:HTTPURLResponse , data:Data)> in
        return URLSession.shared.rx.response(request: request)
      }
    // 4. TO SEND RESPONSE TO NEW SUBSCRIBERS RATHER THAN CREATE NEW ONE
      .share(replay: 1, scope: .whileConnected)
    
    response.filter { response,_  in
      return 200..<300 ~= response.statusCode
    }
    
  }
  
  func processEvents(_ newEvents: [Event]) {
    
  }

  // MARK: - Table Data Source
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return events.value.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let event = events.value[indexPath.row]

    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
    cell.textLabel?.text = event.actor.name
    cell.detailTextLabel?.text = event.repo.name + ", " + event.action.replacingOccurrences(of: "Event", with: "").lowercased()
    cell.imageView?.kf.setImage(with: event.actor.avatar, placeholder: UIImage(named: "blank-avatar"))
    return cell
  }
}
