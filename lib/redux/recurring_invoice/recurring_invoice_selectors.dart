import 'package:invoiceninja_flutter/data/models/invoice_model.dart';
import 'package:invoiceninja_flutter/redux/static/static_state.dart';
import 'package:memoize/memoize.dart';
import 'package:built_collection/built_collection.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/ui/list_ui_state.dart';

var memoizedFilteredRecurringInvoiceList = memo8((
  String filterEntityId,
  EntityType filterEntityType,
  BuiltMap<String, InvoiceEntity> recurringInvoiceMap,
  BuiltMap<String, ClientEntity> clientMap,
  BuiltList<String> recurringInvoiceList,
  ListUIState recurringInvoiceListState,
  StaticState staticState,
  BuiltMap<String, UserEntity> userMap,
) =>
    filteredRecurringInvoicesSelector(
      filterEntityId,
      filterEntityType,
      recurringInvoiceMap,
      clientMap,
      recurringInvoiceList,
      recurringInvoiceListState,
      staticState,
      userMap,
    ));

List<String> filteredRecurringInvoicesSelector(
  String filterEntityId,
  EntityType filterEntityType,
  BuiltMap<String, InvoiceEntity> recurringInvoiceMap,
  BuiltMap<String, ClientEntity> clientMap,
  BuiltList<String> recurringInvoiceList,
  ListUIState invoiceListState,
  StaticState staticState,
  BuiltMap<String, UserEntity> userMap,
) {
  final list = recurringInvoiceList.where((recurringInvoiceId) {
    final invoice = recurringInvoiceMap[recurringInvoiceId];
    final client =
        clientMap[invoice.clientId] ?? ClientEntity(id: invoice.clientId);

    if (!client.isActive &&
        !client.matchesEntityFilter(filterEntityType, filterEntityId)) {
      return false;
    }

    if (filterEntityType == EntityType.client && client.id != filterEntityId) {
      return false;
    } else if (filterEntityType == EntityType.user &&
        invoice.assignedUserId != filterEntityId) {
      return false;
    } else if (filterEntityType == EntityType.project &&
        invoice.projectId != filterEntityId) {
      return false;
    }

    if (!invoice.matchesStates(invoiceListState.stateFilters)) {
      return false;
    }
    if (!invoice.matchesStatuses(invoiceListState.statusFilters)) {
      return false;
    }
    if (!invoice.matchesFilter(invoiceListState.filter) &&
        !client.matchesFilter(invoiceListState.filter)) {
      return false;
    }
    if (invoiceListState.custom1Filters.isNotEmpty &&
        !invoiceListState.custom1Filters.contains(invoice.customValue1)) {
      return false;
    }
    if (invoiceListState.custom2Filters.isNotEmpty &&
        !invoiceListState.custom2Filters.contains(invoice.customValue2)) {
      return false;
    }
    if (invoiceListState.custom3Filters.isNotEmpty &&
        !invoiceListState.custom3Filters.contains(invoice.customValue3)) {
      return false;
    }
    if (invoiceListState.custom4Filters.isNotEmpty &&
        !invoiceListState.custom4Filters.contains(invoice.customValue4)) {
      return false;
    }
    return true;
  }).toList();

  list.sort((recurringInvoiceAId, recurringInvoiceBId) {
    final recurringInvoiceA = recurringInvoiceMap[recurringInvoiceAId];
    final recurringInvoiceB = recurringInvoiceMap[recurringInvoiceBId];

    return recurringInvoiceA.compareTo(
      invoice: recurringInvoiceB,
      sortField: invoiceListState.sortField,
      sortAscending: invoiceListState.sortAscending,
      clientMap: clientMap,
      staticState: staticState,
      userMap: userMap,
    );
  });

  return list;
}

var memoizedRecurringInvoiceStatsForClient = memo2(
    (String clientId, BuiltMap<String, InvoiceEntity> invoiceMap) =>
        recurringInvoiceStatsForClient(clientId, invoiceMap));

EntityStats recurringInvoiceStatsForClient(
    String clientId, BuiltMap<String, InvoiceEntity> invoiceMap) {
  int countActive = 0;
  int countArchived = 0;
  invoiceMap.forEach((invoiceId, invoice) {
    if (invoice.clientId == clientId) {
      if (invoice.isActive) {
        countActive++;
      } else if (invoice.isArchived) {
        countArchived++;
      }
    }
  });

  return EntityStats(countActive: countActive, countArchived: countArchived);
}

var memoizedRecurringInvoiceStatsForUser = memo2(
    (String userId, BuiltMap<String, InvoiceEntity> invoiceMap) =>
        recurringInvoiceStatsForUser(userId, invoiceMap));

EntityStats recurringInvoiceStatsForUser(
    String userId, BuiltMap<String, InvoiceEntity> invoiceMap) {
  int countActive = 0;
  int countArchived = 0;
  invoiceMap.forEach((invoiceId, invoice) {
    if (invoice.assignedUserId == userId) {
      if (invoice.isActive) {
        countActive++;
      } else if (invoice.isDeleted) {
        countArchived++;
      }
    }
  });

  return EntityStats(countActive: countActive, countArchived: countArchived);
}

var memoizedRecurringInvoiceStatsForInvoice = memo2(
    (String invoiceId, BuiltMap<String, InvoiceEntity> invoiceMap) =>
        recurringInvoiceStatsForInvoice(invoiceId, invoiceMap));

EntityStats recurringInvoiceStatsForInvoice(
    String recurrinInvoiceId, BuiltMap<String, InvoiceEntity> invoiceMap) {
  int countActive = 0;
  int countArchived = 0;
  invoiceMap.forEach((invoiceId, invoice) {
    if (invoice.recurringId == recurrinInvoiceId) {
      if (invoice.isActive) {
        countActive++;
      } else if (invoice.isDeleted) {
        countArchived++;
      }
    }
  });

  return EntityStats(countActive: countActive, countArchived: countArchived);
}

bool hasRecurringInvoiceChanges(InvoiceEntity recurringInvoice,
        BuiltMap<String, InvoiceEntity> recurringInvoiceMap) =>
    recurringInvoice.isNew
        ? recurringInvoice.isChanged
        : recurringInvoice != recurringInvoiceMap[recurringInvoice.id];
