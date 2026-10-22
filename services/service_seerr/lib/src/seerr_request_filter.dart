import 'models/seerr_request.dart';

/// The chips over the Requests tab. Each one keeps the requests of one
/// request status (1 pending, 2 approved, 3 declined); [all] keeps every
/// one, failed requests included.
enum SeerrRequestFilter {
  all('All', 'No requests', 'No media requests yet.'),
  pending('Pending', 'No pending requests', 'Nothing is waiting for approval.'),
  approved('Approved', 'No approved requests', 'No request has been approved.'),
  declined('Declined', 'No declined requests', 'No request has been declined.');

  const SeerrRequestFilter(this.label, this.emptyTitle, this.emptyMessage);

  final String label;
  final String emptyTitle;
  final String emptyMessage;

  /// Whether [request] shows under this chip.
  bool keeps(SeerrRequest request) => switch (this) {
        SeerrRequestFilter.all => true,
        SeerrRequestFilter.pending => request.status == 1,
        SeerrRequestFilter.approved => request.status == 2,
        SeerrRequestFilter.declined => request.status == 3,
      };

  /// [requests] cut down to this chip, in the order they came.
  List<SeerrRequest> apply(List<SeerrRequest> requests) => this == all
      ? requests
      : <SeerrRequest>[
          for (final SeerrRequest r in requests)
            if (keeps(r)) r,
        ];
}
