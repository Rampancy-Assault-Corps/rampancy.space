// GENERATED – do not modify.
import "package:rampancy_assault_corps_models/rampancy_assault_corps_models.dart";
import "package:rampancy_assault_corps_models/gen/artifacts.gen.dart";
import "dart:core";
import "package:fire_crud/fire_crud.dart";
import "package:fire_api/fire_api.dart";

/// CRUD Extensions for User
extension XFCrudBase$User on User {
  /// Gets this document (self) live and returns a new instance of [User] representing the new data
  Future<User?> get() => getSelfRaw<User>();

  /// Gets this document (self) live and caches it for the next time, returns a new instance of [User] representing the new data
  Future<User?> getCached() => getCachedSelfRaw<User>();

  /// Shorthand for documentId! Gets this instance id
  String get userId => documentId!;

  /// Opens a self stream of [User] representing this document
  Stream<User?> stream() => streamSelfRaw<User>();

  /// Sets this [User] document to a new value
  Future<void> set(User to) => setSelfRaw<User>(to);

  /// Updates properties of this [User] with {"fieldName": VALUE, ...}
  Future<void> update(Map<String, dynamic> u) => updateSelfRaw<User>(u);

  /// Deletes this [User] document
  Future<void> delete() => deleteSelfRaw<User>();

  /// Sets this [User] document atomically by getting first then setting.
  Future<void> setAtomic(User Function(User?) txn) =>
      setSelfAtomicRaw<User>(txn);

  /// Modifies properties of the [User] document (as a unique child) atomically.
  Future<void> modify({
    /// Replaces the value of [name] with a new value atomically.
    String? name,

    /// Removes the [name] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteName = false,

    /// Replaces the value of [email] with a new value atomically.
    String? email,

    /// Removes the [email] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteEmail = false,

    /// Replaces the value of [profileHash] with a new value atomically.
    String? profileHash,

    /// Removes the [profileHash] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteProfileHash = false,
    bool $z = false,
  }) => updateSelfRaw<User>({
    if (name != null) 'name': name,
    if (deleteName) 'name': FieldValue.delete(),
    if (email != null) 'email': email,
    if (deleteEmail) 'email': FieldValue.delete(),
    if (profileHash != null) 'profileHash': profileHash,
    if (deleteProfileHash) 'profileHash': FieldValue.delete(),
  });
}

/// CRUD Extensions for (UNIQUE) User.UserSettings
extension XFCrudU$User$UserSettings on User {
  /// Gets the [UserSettings] document (as a unique child)
  Future<UserSettings?> getUserSettings() => getUnique<UserSettings>();

  /// Gets the [UserSettings] document (as a unique child) and caches it for the next time
  Future<UserSettings?> getUserSettingsCached() =>
      getCachedUnique<UserSettings>();

  /// Sets the [UserSettings] document (as a unique child) to a new value
  Future<void> setUserSettings(UserSettings value) =>
      setUnique<UserSettings>(value);

  /// Deletes the [UserSettings] document (as a unique child)
  Future<void> deleteUserSettings() => deleteUnique<UserSettings>();

  /// Streams the [UserSettings] document (as a unique child)
  Stream<UserSettings?> streamUserSettings() => streamUnique<UserSettings>();

  /// Updates properties of the [UserSettings] document (as a unique child) with {"fieldName": VALUE, ...}
  Future<void> updateUserSettings(Map<String, dynamic> updates) =>
      updateUnique<UserSettings>(updates);

  /// Sets the [UserSettings] document (as a unique child) atomically by getting first then setting.
  Future<void> setUserSettingsAtomic(
    UserSettings Function(UserSettings?) txn,
  ) => setUniqueAtomic<UserSettings>(txn);

  /// Ensures that the [UserSettings] document (as a unique child) exists, if not it will be created with [or]
  Future<void> ensureUserSettingsExists(UserSettings or) =>
      ensureExistsUnique<UserSettings>(or);

  /// Gets a model instance of [UserSettings] bound with the unique id that can be used to access child models
  /// without network io (unique child).
  UserSettings userSettingsModel() => modelUnique<UserSettings>();

  /// Modifies properties of the [UserSettings] document (as a unique child) atomically.
  Future<void> modifyUserSettings({
    /// Replaces the value of [themeMode] with a new value atomically.
    ThemeMode? themeMode,

    /// Removes the [themeMode] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteThemeMode = false,
    bool $z = false,
  }) => updateUnique<UserSettings>({
    if (themeMode != null) 'themeMode': themeMode.name,
    if (deleteThemeMode) 'themeMode': FieldValue.delete(),
  });
}

/// CRUD Extensions for UserSettings
/// Parent Model is [User]
extension XFCrudBase$UserSettings on UserSettings {
  /// Gets this document (self) live and returns a new instance of [UserSettings] representing the new data
  Future<UserSettings?> get() => getSelfRaw<UserSettings>();

  /// Gets this document (self) live and caches it for the next time, returns a new instance of [UserSettings] representing the new data
  Future<UserSettings?> getCached() => getCachedSelfRaw<UserSettings>();

  /// Shorthand for documentId! Gets this instance id
  String get userSettingsId => documentId!;

  User get parentUserModel => parentModel<User>();

  String get parentUserId => parentDocumentId!;

  /// Opens a self stream of [UserSettings] representing this document
  Stream<UserSettings?> stream() => streamSelfRaw<UserSettings>();

  /// Sets this [UserSettings] document to a new value
  Future<void> set(UserSettings to) => setSelfRaw<UserSettings>(to);

  /// Updates properties of this [UserSettings] with {"fieldName": VALUE, ...}
  Future<void> update(Map<String, dynamic> u) => updateSelfRaw<UserSettings>(u);

  /// Deletes this [UserSettings] document
  Future<void> delete() => deleteSelfRaw<UserSettings>();

  /// Sets this [UserSettings] document atomically by getting first then setting.
  Future<void> setAtomic(UserSettings Function(UserSettings?) txn) =>
      setSelfAtomicRaw<UserSettings>(txn);

  /// Modifies properties of the [UserSettings] document (as a unique child) atomically.
  Future<void> modify({
    /// Replaces the value of [themeMode] with a new value atomically.
    ThemeMode? themeMode,

    /// Removes the [themeMode] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteThemeMode = false,
    bool $z = false,
  }) => updateSelfRaw<UserSettings>({
    if (themeMode != null) 'themeMode': themeMode.name,
    if (deleteThemeMode) 'themeMode': FieldValue.delete(),
  });
}

/// CRUD Extensions for ServerCommand
extension XFCrudBase$ServerCommand on ServerCommand {
  /// Gets this document (self) live and returns a new instance of [ServerCommand] representing the new data
  Future<ServerCommand?> get() => getSelfRaw<ServerCommand>();

  /// Gets this document (self) live and caches it for the next time, returns a new instance of [ServerCommand] representing the new data
  Future<ServerCommand?> getCached() => getCachedSelfRaw<ServerCommand>();

  /// Shorthand for documentId! Gets this instance id
  String get serverCommandId => documentId!;

  /// Opens a self stream of [ServerCommand] representing this document
  Stream<ServerCommand?> stream() => streamSelfRaw<ServerCommand>();

  /// Sets this [ServerCommand] document to a new value
  Future<void> set(ServerCommand to) => setSelfRaw<ServerCommand>(to);

  /// Updates properties of this [ServerCommand] with {"fieldName": VALUE, ...}
  Future<void> update(Map<String, dynamic> u) =>
      updateSelfRaw<ServerCommand>(u);

  /// Deletes this [ServerCommand] document
  Future<void> delete() => deleteSelfRaw<ServerCommand>();

  /// Sets this [ServerCommand] document atomically by getting first then setting.
  Future<void> setAtomic(ServerCommand Function(ServerCommand?) txn) =>
      setSelfAtomicRaw<ServerCommand>(txn);

  /// Modifies properties of the [ServerCommand] document (as a unique child) atomically.
  Future<void> modify({
    /// Replaces the value of [user] with a new value atomically.
    String? user,

    /// Removes the [user] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteUser = false,
    bool $z = false,
  }) => updateSelfRaw<ServerCommand>({
    if (user != null) 'user': user,
    if (deleteUser) 'user': FieldValue.delete(),
  });
}

/// CRUD Extensions for (UNIQUE) ServerCommand.ServerResponse
extension XFCrudU$ServerCommand$ServerResponse on ServerCommand {
  /// Gets the [ServerResponse] document (as a unique child)
  Future<ServerResponse?> getServerResponse() => getUnique<ServerResponse>();

  /// Gets the [ServerResponse] document (as a unique child) and caches it for the next time
  Future<ServerResponse?> getServerResponseCached() =>
      getCachedUnique<ServerResponse>();

  /// Sets the [ServerResponse] document (as a unique child) to a new value
  Future<void> setServerResponse(ServerResponse value) =>
      setUnique<ServerResponse>(value);

  /// Deletes the [ServerResponse] document (as a unique child)
  Future<void> deleteServerResponse() => deleteUnique<ServerResponse>();

  /// Streams the [ServerResponse] document (as a unique child)
  Stream<ServerResponse?> streamServerResponse() =>
      streamUnique<ServerResponse>();

  /// Updates properties of the [ServerResponse] document (as a unique child) with {"fieldName": VALUE, ...}
  Future<void> updateServerResponse(Map<String, dynamic> updates) =>
      updateUnique<ServerResponse>(updates);

  /// Sets the [ServerResponse] document (as a unique child) atomically by getting first then setting.
  Future<void> setServerResponseAtomic(
    ServerResponse Function(ServerResponse?) txn,
  ) => setUniqueAtomic<ServerResponse>(txn);

  /// Ensures that the [ServerResponse] document (as a unique child) exists, if not it will be created with [or]
  Future<void> ensureServerResponseExists(ServerResponse or) =>
      ensureExistsUnique<ServerResponse>(or);

  /// Gets a model instance of [ServerResponse] bound with the unique id that can be used to access child models
  /// without network io (unique child).
  ServerResponse serverResponseModel() => modelUnique<ServerResponse>();

  /// Modifies properties of the [ServerResponse] document (as a unique child) atomically.
  Future<void> modifyServerResponse({
    /// Replaces the value of [user] with a new value atomically.
    String? user,

    /// Removes the [user] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteUser = false,
    bool $z = false,
  }) => updateUnique<ServerResponse>({
    if (user != null) 'user': user,
    if (deleteUser) 'user': FieldValue.delete(),
  });
}

/// CRUD Extensions for ServerResponse
/// Parent Model is [ServerCommand]
extension XFCrudBase$ServerResponse on ServerResponse {
  /// Gets this document (self) live and returns a new instance of [ServerResponse] representing the new data
  Future<ServerResponse?> get() => getSelfRaw<ServerResponse>();

  /// Gets this document (self) live and caches it for the next time, returns a new instance of [ServerResponse] representing the new data
  Future<ServerResponse?> getCached() => getCachedSelfRaw<ServerResponse>();

  /// Shorthand for documentId! Gets this instance id
  String get serverResponseId => documentId!;

  ServerCommand get parentServerCommandModel => parentModel<ServerCommand>();

  String get parentServerCommandId => parentDocumentId!;

  /// Opens a self stream of [ServerResponse] representing this document
  Stream<ServerResponse?> stream() => streamSelfRaw<ServerResponse>();

  /// Sets this [ServerResponse] document to a new value
  Future<void> set(ServerResponse to) => setSelfRaw<ServerResponse>(to);

  /// Updates properties of this [ServerResponse] with {"fieldName": VALUE, ...}
  Future<void> update(Map<String, dynamic> u) =>
      updateSelfRaw<ServerResponse>(u);

  /// Deletes this [ServerResponse] document
  Future<void> delete() => deleteSelfRaw<ServerResponse>();

  /// Sets this [ServerResponse] document atomically by getting first then setting.
  Future<void> setAtomic(ServerResponse Function(ServerResponse?) txn) =>
      setSelfAtomicRaw<ServerResponse>(txn);

  /// Modifies properties of the [ServerResponse] document (as a unique child) atomically.
  Future<void> modify({
    /// Replaces the value of [user] with a new value atomically.
    String? user,

    /// Removes the [user] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteUser = false,
    bool $z = false,
  }) => updateSelfRaw<ServerResponse>({
    if (user != null) 'user': user,
    if (deleteUser) 'user': FieldValue.delete(),
  });
}

/// CRUD Extensions for AccountLink
extension XFCrudBase$AccountLink on AccountLink {
  /// Gets this document (self) live and returns a new instance of [AccountLink] representing the new data
  Future<AccountLink?> get() => getSelfRaw<AccountLink>();

  /// Gets this document (self) live and caches it for the next time, returns a new instance of [AccountLink] representing the new data
  Future<AccountLink?> getCached() => getCachedSelfRaw<AccountLink>();

  /// Shorthand for documentId! Gets this instance id
  String get accountLinkId => documentId!;

  /// Opens a self stream of [AccountLink] representing this document
  Stream<AccountLink?> stream() => streamSelfRaw<AccountLink>();

  /// Sets this [AccountLink] document to a new value
  Future<void> set(AccountLink to) => setSelfRaw<AccountLink>(to);

  /// Updates properties of this [AccountLink] with {"fieldName": VALUE, ...}
  Future<void> update(Map<String, dynamic> u) => updateSelfRaw<AccountLink>(u);

  /// Deletes this [AccountLink] document
  Future<void> delete() => deleteSelfRaw<AccountLink>();

  /// Sets this [AccountLink] document atomically by getting first then setting.
  Future<void> setAtomic(AccountLink Function(AccountLink?) txn) =>
      setSelfAtomicRaw<AccountLink>(txn);

  /// Modifies properties of the [AccountLink] document (as a unique child) atomically.
  Future<void> modify({
    /// Replaces the value of [discordId] with a new value atomically.
    String? discordId,

    /// Removes the [discordId] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteDiscordId = false,

    /// Replaces the value of [discordUsername] with a new value atomically.
    String? discordUsername,

    /// Removes the [discordUsername] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteDiscordUsername = false,

    /// Replaces the value of [discordGlobalName] with a new value atomically.
    String? discordGlobalName,

    /// Removes the [discordGlobalName] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteDiscordGlobalName = false,

    /// Replaces the value of [discordAvatarHash] with a new value atomically.
    String? discordAvatarHash,

    /// Removes the [discordAvatarHash] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteDiscordAvatarHash = false,

    /// Changes (increment/decrement) [discordLinkedAt] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaDiscordLinkedAt,

    /// Replaces the value of [discordLinkedAt] with a new value atomically.
    int? discordLinkedAt,

    /// Removes the [discordLinkedAt] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteDiscordLinkedAt = false,

    /// Replaces the value of [bungieConnected] with a new value atomically.
    bool? bungieConnected,

    /// Removes the [bungieConnected] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteBungieConnected = false,

    /// Replaces the value of [bungieAccountId] with a new value atomically.
    String? bungieAccountId,

    /// Removes the [bungieAccountId] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteBungieAccountId = false,

    /// Replaces the value of [bungieDisplayName] with a new value atomically.
    String? bungieDisplayName,

    /// Removes the [bungieDisplayName] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteBungieDisplayName = false,

    /// Replaces the value of [bungieAvatarPath] with a new value atomically.
    String? bungieAvatarPath,

    /// Removes the [bungieAvatarPath] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteBungieAvatarPath = false,

    /// Replaces the value of [bungieMarathonMembershipId] with a new value atomically.
    String? bungieMarathonMembershipId,

    /// Removes the [bungieMarathonMembershipId] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteBungieMarathonMembershipId = false,

    /// Changes (increment/decrement) [bungieLinkedAt] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaBungieLinkedAt,

    /// Replaces the value of [bungieLinkedAt] with a new value atomically.
    int? bungieLinkedAt,

    /// Removes the [bungieLinkedAt] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteBungieLinkedAt = false,

    /// Replaces the value of [bungieRefreshCiphertext] with a new value atomically.
    String? bungieRefreshCiphertext,

    /// Removes the [bungieRefreshCiphertext] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteBungieRefreshCiphertext = false,

    /// Replaces the value of [bungieRefreshNonce] with a new value atomically.
    String? bungieRefreshNonce,

    /// Removes the [bungieRefreshNonce] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteBungieRefreshNonce = false,

    /// Changes (increment/decrement) [bungieRefreshExpiresAt] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaBungieRefreshExpiresAt,

    /// Replaces the value of [bungieRefreshExpiresAt] with a new value atomically.
    int? bungieRefreshExpiresAt,

    /// Removes the [bungieRefreshExpiresAt] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteBungieRefreshExpiresAt = false,

    /// Changes (increment/decrement) [updatedAt] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaUpdatedAt,

    /// Replaces the value of [updatedAt] with a new value atomically.
    int? updatedAt,

    /// Removes the [updatedAt] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteUpdatedAt = false,
    bool $z = false,
  }) => updateSelfRaw<AccountLink>({
    if (discordId != null) 'discordId': discordId,
    if (deleteDiscordId) 'discordId': FieldValue.delete(),
    if (discordUsername != null) 'discordUsername': discordUsername,
    if (deleteDiscordUsername) 'discordUsername': FieldValue.delete(),
    if (discordGlobalName != null) 'discordGlobalName': discordGlobalName,
    if (deleteDiscordGlobalName) 'discordGlobalName': FieldValue.delete(),
    if (discordAvatarHash != null) 'discordAvatarHash': discordAvatarHash,
    if (deleteDiscordAvatarHash) 'discordAvatarHash': FieldValue.delete(),
    if (discordLinkedAt != null) 'discordLinkedAt': discordLinkedAt,
    if (deltaDiscordLinkedAt != null)
      'discordLinkedAt': FieldValue.increment(deltaDiscordLinkedAt),
    if (deleteDiscordLinkedAt) 'discordLinkedAt': FieldValue.delete(),
    if (bungieConnected != null) 'bungieConnected': bungieConnected,
    if (deleteBungieConnected) 'bungieConnected': FieldValue.delete(),
    if (bungieAccountId != null) 'bungieAccountId': bungieAccountId,
    if (deleteBungieAccountId) 'bungieAccountId': FieldValue.delete(),
    if (bungieDisplayName != null) 'bungieDisplayName': bungieDisplayName,
    if (deleteBungieDisplayName) 'bungieDisplayName': FieldValue.delete(),
    if (bungieAvatarPath != null) 'bungieAvatarPath': bungieAvatarPath,
    if (deleteBungieAvatarPath) 'bungieAvatarPath': FieldValue.delete(),
    if (bungieMarathonMembershipId != null)
      'bungieMarathonMembershipId': bungieMarathonMembershipId,
    if (deleteBungieMarathonMembershipId)
      'bungieMarathonMembershipId': FieldValue.delete(),
    if (bungieLinkedAt != null) 'bungieLinkedAt': bungieLinkedAt,
    if (deltaBungieLinkedAt != null)
      'bungieLinkedAt': FieldValue.increment(deltaBungieLinkedAt),
    if (deleteBungieLinkedAt) 'bungieLinkedAt': FieldValue.delete(),
    if (bungieRefreshCiphertext != null)
      'bungieRefreshCiphertext': bungieRefreshCiphertext,
    if (deleteBungieRefreshCiphertext)
      'bungieRefreshCiphertext': FieldValue.delete(),
    if (bungieRefreshNonce != null) 'bungieRefreshNonce': bungieRefreshNonce,
    if (deleteBungieRefreshNonce) 'bungieRefreshNonce': FieldValue.delete(),
    if (bungieRefreshExpiresAt != null)
      'bungieRefreshExpiresAt': bungieRefreshExpiresAt,
    if (deltaBungieRefreshExpiresAt != null)
      'bungieRefreshExpiresAt': FieldValue.increment(
        deltaBungieRefreshExpiresAt,
      ),
    if (deleteBungieRefreshExpiresAt)
      'bungieRefreshExpiresAt': FieldValue.delete(),
    if (updatedAt != null) 'updatedAt': updatedAt,
    if (deltaUpdatedAt != null)
      'updatedAt': FieldValue.increment(deltaUpdatedAt),
    if (deleteUpdatedAt) 'updatedAt': FieldValue.delete(),
  });
}

/// CRUD Extensions for AccountLink.BungieMembership
extension XFCrud$AccountLink$BungieMembership on AccountLink {
  /// Counts the number of [BungieMembership] inside [AccountLink] in the collection optionally filtered by [query]
  Future<int> countBungieMemberships([
    CollectionReference Function(CollectionReference ref)? query,
  ]) => $count<BungieMembership>(query);

  /// Gets all [BungieMembership] inside [AccountLink] in the collection optionally filtered by [query]
  Future<List<BungieMembership>> getBungieMemberships([
    CollectionReference Function(CollectionReference ref)? query,
  ]) => getAll<BungieMembership>(query);

  /// Gets a document page starting at the beginning of the collection. Returns a [ModelPage<BungieMembership>] that contains the models and nextPage method to get the next page
  Future<ModelPage<BungieMembership>?> paginateBungieMemberships({
    int pageSize = 50,
    bool reversed = false,
    CollectionReference Function(CollectionReference ref)? query,
  }) => paginate<BungieMembership>(
    pageSize: pageSize,
    reversed: reversed,
    query: query,
  );

  /// Opens a stream of all [BungieMembership] inside [AccountLink] in the collection optionally filtered by [query]
  Stream<List<BungieMembership>> streamBungieMemberships([
    CollectionReference Function(CollectionReference ref)? query,
  ]) => streamAll<BungieMembership>(query);

  /// Sets the [BungieMembership] inside [AccountLink] document with [id] to a new value
  Future<void> setBungieMembership(String id, BungieMembership value) =>
      $set<BungieMembership>(id, value);

  /// Gets the [BungieMembership] inside [AccountLink] document with [id]
  Future<BungieMembership?> getBungieMembership(String id) =>
      $get<BungieMembership>(id);

  /// Gets the [BungieMembership] inside [AccountLink] document with [id] and caches it for the next time
  Future<BungieMembership?> getBungieMembershipCached(String id) =>
      getCached<BungieMembership>(id);

  /// Updates properties of the [BungieMembership] inside [AccountLink] document with [id] with {"fieldName": VALUE, ...}
  Future<void> updateBungieMembership(
    String id,
    Map<String, dynamic> updates,
  ) => $update<BungieMembership>(id, updates);

  /// Opens a stream of the [BungieMembership] inside [AccountLink] document with [id]
  Stream<BungieMembership?> streamBungieMembership(String id) =>
      $stream<BungieMembership>(id);

  /// Deletes the [BungieMembership] inside [AccountLink] document with [id]
  Future<void> deleteBungieMembership(String id) =>
      $delete<BungieMembership>(id);

  /// Adds a new [BungieMembership] inside [AccountLink] document with a new id and returns the created model with the id set
  Future<BungieMembership> addBungieMembership(
    BungieMembership value, {
    bool useULID = false,
  }) => $add<BungieMembership>(value, useULID: useULID);

  /// Sets the [BungieMembership] inside [AccountLink] document with [id] atomically by getting first then setting.
  Future<void> setBungieMembershipAtomic(
    String id,
    BungieMembership Function(BungieMembership?) txn,
  ) => $setAtomic<BungieMembership>(id, txn);

  /// Ensures that the [BungieMembership] inside [AccountLink] document with [id] exists, if not it will be created with [or]
  Future<void> ensureBungieMembershipExists(String id, BungieMembership or) =>
      $ensureExists<BungieMembership>(id, or);

  /// Gets a model instance of [BungieMembership] inside [AccountLink] bound with [id] that can be used to access child models
  /// without network io.
  BungieMembership bungieMembershipModel(String id) =>
      $model<BungieMembership>(id);

  /// Modifies properties of the [BungieMembership] inside [AccountLink] document with [id] atomically.
  Future<void> modifyBungieMembership({
    required String id,

    /// Replaces the value of [membershipId] with a new value atomically.
    String? membershipId,

    /// Removes the [membershipId] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteMembershipId = false,

    /// Changes (increment/decrement) [membershipType] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaMembershipType,

    /// Replaces the value of [membershipType] with a new value atomically.
    int? membershipType,

    /// Removes the [membershipType] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteMembershipType = false,

    /// Replaces the value of [displayName] with a new value atomically.
    String? displayName,

    /// Removes the [displayName] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteDisplayName = false,

    /// Replaces the value of [iconPath] with a new value atomically.
    String? iconPath,

    /// Removes the [iconPath] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteIconPath = false,

    /// Changes (increment/decrement) [crossSaveOverride] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaCrossSaveOverride,

    /// Replaces the value of [crossSaveOverride] with a new value atomically.
    int? crossSaveOverride,

    /// Removes the [crossSaveOverride] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteCrossSaveOverride = false,

    /// Replaces the value of [isPrimary] with a new value atomically.
    bool? isPrimary,

    /// Removes the [isPrimary] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteIsPrimary = false,

    /// Changes (increment/decrement) [updatedAt] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaUpdatedAt,

    /// Replaces the value of [updatedAt] with a new value atomically.
    int? updatedAt,

    /// Removes the [updatedAt] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteUpdatedAt = false,
    bool $z = false,
  }) => $update<BungieMembership>(id, {
    if (membershipId != null) 'membershipId': membershipId,
    if (deleteMembershipId) 'membershipId': FieldValue.delete(),
    if (membershipType != null) 'membershipType': membershipType,
    if (deltaMembershipType != null)
      'membershipType': FieldValue.increment(deltaMembershipType),
    if (deleteMembershipType) 'membershipType': FieldValue.delete(),
    if (displayName != null) 'displayName': displayName,
    if (deleteDisplayName) 'displayName': FieldValue.delete(),
    if (iconPath != null) 'iconPath': iconPath,
    if (deleteIconPath) 'iconPath': FieldValue.delete(),
    if (crossSaveOverride != null) 'crossSaveOverride': crossSaveOverride,
    if (deltaCrossSaveOverride != null)
      'crossSaveOverride': FieldValue.increment(deltaCrossSaveOverride),
    if (deleteCrossSaveOverride) 'crossSaveOverride': FieldValue.delete(),
    if (isPrimary != null) 'isPrimary': isPrimary,
    if (deleteIsPrimary) 'isPrimary': FieldValue.delete(),
    if (updatedAt != null) 'updatedAt': updatedAt,
    if (deltaUpdatedAt != null)
      'updatedAt': FieldValue.increment(deltaUpdatedAt),
    if (deleteUpdatedAt) 'updatedAt': FieldValue.delete(),
  });
}

/// CRUD Extensions for BungieMembership
/// Parent Model is [AccountLink]
extension XFCrudBase$BungieMembership on BungieMembership {
  /// Gets this document (self) live and returns a new instance of [BungieMembership] representing the new data
  Future<BungieMembership?> get() => getSelfRaw<BungieMembership>();

  /// Gets this document (self) live and caches it for the next time, returns a new instance of [BungieMembership] representing the new data
  Future<BungieMembership?> getCached() => getCachedSelfRaw<BungieMembership>();

  /// Shorthand for documentId! Gets this instance id
  String get bungieMembershipId => documentId!;

  AccountLink get parentAccountLinkModel => parentModel<AccountLink>();

  String get parentAccountLinkId => parentDocumentId!;

  /// Opens a self stream of [BungieMembership] representing this document
  Stream<BungieMembership?> stream() => streamSelfRaw<BungieMembership>();

  /// Sets this [BungieMembership] document to a new value
  Future<void> set(BungieMembership to) => setSelfRaw<BungieMembership>(to);

  /// Updates properties of this [BungieMembership] with {"fieldName": VALUE, ...}
  Future<void> update(Map<String, dynamic> u) =>
      updateSelfRaw<BungieMembership>(u);

  /// Deletes this [BungieMembership] document
  Future<void> delete() => deleteSelfRaw<BungieMembership>();

  /// Sets this [BungieMembership] document atomically by getting first then setting.
  Future<void> setAtomic(BungieMembership Function(BungieMembership?) txn) =>
      setSelfAtomicRaw<BungieMembership>(txn);

  /// Modifies properties of the [BungieMembership] document (as a unique child) atomically.
  Future<void> modify({
    /// Replaces the value of [membershipId] with a new value atomically.
    String? membershipId,

    /// Removes the [membershipId] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteMembershipId = false,

    /// Changes (increment/decrement) [membershipType] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaMembershipType,

    /// Replaces the value of [membershipType] with a new value atomically.
    int? membershipType,

    /// Removes the [membershipType] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteMembershipType = false,

    /// Replaces the value of [displayName] with a new value atomically.
    String? displayName,

    /// Removes the [displayName] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteDisplayName = false,

    /// Replaces the value of [iconPath] with a new value atomically.
    String? iconPath,

    /// Removes the [iconPath] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteIconPath = false,

    /// Changes (increment/decrement) [crossSaveOverride] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaCrossSaveOverride,

    /// Replaces the value of [crossSaveOverride] with a new value atomically.
    int? crossSaveOverride,

    /// Removes the [crossSaveOverride] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteCrossSaveOverride = false,

    /// Replaces the value of [isPrimary] with a new value atomically.
    bool? isPrimary,

    /// Removes the [isPrimary] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteIsPrimary = false,

    /// Changes (increment/decrement) [updatedAt] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaUpdatedAt,

    /// Replaces the value of [updatedAt] with a new value atomically.
    int? updatedAt,

    /// Removes the [updatedAt] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteUpdatedAt = false,
    bool $z = false,
  }) => updateSelfRaw<BungieMembership>({
    if (membershipId != null) 'membershipId': membershipId,
    if (deleteMembershipId) 'membershipId': FieldValue.delete(),
    if (membershipType != null) 'membershipType': membershipType,
    if (deltaMembershipType != null)
      'membershipType': FieldValue.increment(deltaMembershipType),
    if (deleteMembershipType) 'membershipType': FieldValue.delete(),
    if (displayName != null) 'displayName': displayName,
    if (deleteDisplayName) 'displayName': FieldValue.delete(),
    if (iconPath != null) 'iconPath': iconPath,
    if (deleteIconPath) 'iconPath': FieldValue.delete(),
    if (crossSaveOverride != null) 'crossSaveOverride': crossSaveOverride,
    if (deltaCrossSaveOverride != null)
      'crossSaveOverride': FieldValue.increment(deltaCrossSaveOverride),
    if (deleteCrossSaveOverride) 'crossSaveOverride': FieldValue.delete(),
    if (isPrimary != null) 'isPrimary': isPrimary,
    if (deleteIsPrimary) 'isPrimary': FieldValue.delete(),
    if (updatedAt != null) 'updatedAt': updatedAt,
    if (deltaUpdatedAt != null)
      'updatedAt': FieldValue.increment(deltaUpdatedAt),
    if (deleteUpdatedAt) 'updatedAt': FieldValue.delete(),
  });
}

/// Root CRUD Extensions for RootFireCrud
extension XFCrudRoot$User on RootFireCrud {
  /// Counts the number of [User] in the collection optionally filtered by [query]
  Future<int> countUsers([
    CollectionReference Function(CollectionReference ref)? query,
  ]) => $count<User>(query);

  /// Gets all [User] in the collection optionally filtered by [query]
  Future<List<User>> getUsers([
    CollectionReference Function(CollectionReference ref)? query,
  ]) => getAll<User>(query);

  /// Gets a document page starting at the beginning of the collection. Returns a [ModelPage<User>] that contains the models and nextPage method to get the next page
  Future<ModelPage<User>?> paginateUsers({
    int pageSize = 50,
    bool reversed = false,
    CollectionReference Function(CollectionReference ref)? query,
  }) => paginate<User>(pageSize: pageSize, reversed: reversed, query: query);

  /// Deletes all [User] in the collection optionally filtered by [query]
  Future<void> deleteAllUsers([
    CollectionReference Function(CollectionReference ref)? query,
  ]) => deleteAll<User>(query);

  /// Opens a stream of all [User] in the collection optionally filtered by [query]
  Stream<List<User>> streamUsers([
    CollectionReference Function(CollectionReference ref)? query,
  ]) => streamAll<User>(query);

  /// Sets the [User] document with [id] to a new value
  Future<void> setUser(String id, User value) => $set<User>(id, value);

  /// Gets the [User] document with [id]
  Future<User?> getUser(String id) => $get<User>(id);

  /// Gets the [User] document with [id] and caches it for the next time
  Future<User?> getUserCached(String id) => getCached<User>(id);

  /// Updates properties of the [User] document with [id] with {"fieldName": VALUE, ...}
  Future<void> updateUser(String id, Map<String, dynamic> updates) =>
      $update<User>(id, updates);

  /// Opens a stream of the [User] document with [id]
  Stream<User?> streamUser(String id) => $stream<User>(id);

  /// Deletes the [User] document with [id]
  Future<void> deleteUser(String id) => $delete<User>(id);

  /// Adds a new [User] document with a new id and returns the created model with the id set
  Future<User> addUser(User value, {bool useULID = false}) =>
      $add<User>(value, useULID: useULID);

  /// Sets the [User] document with [id] atomically by getting first then setting.
  Future<void> setUserAtomic(String id, User Function(User?) txn) =>
      $setAtomic<User>(id, txn);

  /// Ensures that the [User] document with [id] exists, if not it will be created with [or]
  Future<void> ensureUserExists(String id, User or) =>
      $ensureExists<User>(id, or);

  /// Gets a model instance of [User] bound with [id] that can be used to access child models
  /// without network io.
  User userModel(String id) => $model<User>(id);

  /// Modifies properties of the [User] document with [id] atomically.
  Future<void> modifyUser({
    required String id,

    /// Replaces the value of [name] with a new value atomically.
    String? name,

    /// Removes the [name] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteName = false,

    /// Replaces the value of [email] with a new value atomically.
    String? email,

    /// Removes the [email] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteEmail = false,

    /// Replaces the value of [profileHash] with a new value atomically.
    String? profileHash,

    /// Removes the [profileHash] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteProfileHash = false,
    bool $z = false,
  }) => $update<User>(id, {
    if (name != null) 'name': name,
    if (deleteName) 'name': FieldValue.delete(),
    if (email != null) 'email': email,
    if (deleteEmail) 'email': FieldValue.delete(),
    if (profileHash != null) 'profileHash': profileHash,
    if (deleteProfileHash) 'profileHash': FieldValue.delete(),
  });
}

/// Root CRUD Extensions for RootFireCrud
extension XFCrudRoot$ServerCommand on RootFireCrud {
  /// Counts the number of [ServerCommand] in the collection optionally filtered by [query]
  Future<int> countServerCommands([
    CollectionReference Function(CollectionReference ref)? query,
  ]) => $count<ServerCommand>(query);

  /// Gets all [ServerCommand] in the collection optionally filtered by [query]
  Future<List<ServerCommand>> getServerCommands([
    CollectionReference Function(CollectionReference ref)? query,
  ]) => getAll<ServerCommand>(query);

  /// Gets a document page starting at the beginning of the collection. Returns a [ModelPage<ServerCommand>] that contains the models and nextPage method to get the next page
  Future<ModelPage<ServerCommand>?> paginateServerCommands({
    int pageSize = 50,
    bool reversed = false,
    CollectionReference Function(CollectionReference ref)? query,
  }) => paginate<ServerCommand>(
    pageSize: pageSize,
    reversed: reversed,
    query: query,
  );

  /// Deletes all [ServerCommand] in the collection optionally filtered by [query]
  Future<void> deleteAllServerCommands([
    CollectionReference Function(CollectionReference ref)? query,
  ]) => deleteAll<ServerCommand>(query);

  /// Opens a stream of all [ServerCommand] in the collection optionally filtered by [query]
  Stream<List<ServerCommand>> streamServerCommands([
    CollectionReference Function(CollectionReference ref)? query,
  ]) => streamAll<ServerCommand>(query);

  /// Sets the [ServerCommand] document with [id] to a new value
  Future<void> setServerCommand(String id, ServerCommand value) =>
      $set<ServerCommand>(id, value);

  /// Gets the [ServerCommand] document with [id]
  Future<ServerCommand?> getServerCommand(String id) => $get<ServerCommand>(id);

  /// Gets the [ServerCommand] document with [id] and caches it for the next time
  Future<ServerCommand?> getServerCommandCached(String id) =>
      getCached<ServerCommand>(id);

  /// Updates properties of the [ServerCommand] document with [id] with {"fieldName": VALUE, ...}
  Future<void> updateServerCommand(String id, Map<String, dynamic> updates) =>
      $update<ServerCommand>(id, updates);

  /// Opens a stream of the [ServerCommand] document with [id]
  Stream<ServerCommand?> streamServerCommand(String id) =>
      $stream<ServerCommand>(id);

  /// Deletes the [ServerCommand] document with [id]
  Future<void> deleteServerCommand(String id) => $delete<ServerCommand>(id);

  /// Adds a new [ServerCommand] document with a new id and returns the created model with the id set
  Future<ServerCommand> addServerCommand(
    ServerCommand value, {
    bool useULID = false,
  }) => $add<ServerCommand>(value, useULID: useULID);

  /// Sets the [ServerCommand] document with [id] atomically by getting first then setting.
  Future<void> setServerCommandAtomic(
    String id,
    ServerCommand Function(ServerCommand?) txn,
  ) => $setAtomic<ServerCommand>(id, txn);

  /// Ensures that the [ServerCommand] document with [id] exists, if not it will be created with [or]
  Future<void> ensureServerCommandExists(String id, ServerCommand or) =>
      $ensureExists<ServerCommand>(id, or);

  /// Gets a model instance of [ServerCommand] bound with [id] that can be used to access child models
  /// without network io.
  ServerCommand serverCommandModel(String id) => $model<ServerCommand>(id);

  /// Modifies properties of the [ServerCommand] document with [id] atomically.
  Future<void> modifyServerCommand({
    required String id,

    /// Replaces the value of [user] with a new value atomically.
    String? user,

    /// Removes the [user] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteUser = false,
    bool $z = false,
  }) => $update<ServerCommand>(id, {
    if (user != null) 'user': user,
    if (deleteUser) 'user': FieldValue.delete(),
  });
}

/// Root CRUD Extensions for RootFireCrud
extension XFCrudRoot$AccountLink on RootFireCrud {
  /// Counts the number of [AccountLink] in the collection optionally filtered by [query]
  Future<int> countAccountLinks([
    CollectionReference Function(CollectionReference ref)? query,
  ]) => $count<AccountLink>(query);

  /// Gets all [AccountLink] in the collection optionally filtered by [query]
  Future<List<AccountLink>> getAccountLinks([
    CollectionReference Function(CollectionReference ref)? query,
  ]) => getAll<AccountLink>(query);

  /// Gets a document page starting at the beginning of the collection. Returns a [ModelPage<AccountLink>] that contains the models and nextPage method to get the next page
  Future<ModelPage<AccountLink>?> paginateAccountLinks({
    int pageSize = 50,
    bool reversed = false,
    CollectionReference Function(CollectionReference ref)? query,
  }) => paginate<AccountLink>(
    pageSize: pageSize,
    reversed: reversed,
    query: query,
  );

  /// Deletes all [AccountLink] in the collection optionally filtered by [query]
  Future<void> deleteAllAccountLinks([
    CollectionReference Function(CollectionReference ref)? query,
  ]) => deleteAll<AccountLink>(query);

  /// Opens a stream of all [AccountLink] in the collection optionally filtered by [query]
  Stream<List<AccountLink>> streamAccountLinks([
    CollectionReference Function(CollectionReference ref)? query,
  ]) => streamAll<AccountLink>(query);

  /// Sets the [AccountLink] document with [id] to a new value
  Future<void> setAccountLink(String id, AccountLink value) =>
      $set<AccountLink>(id, value);

  /// Gets the [AccountLink] document with [id]
  Future<AccountLink?> getAccountLink(String id) => $get<AccountLink>(id);

  /// Gets the [AccountLink] document with [id] and caches it for the next time
  Future<AccountLink?> getAccountLinkCached(String id) =>
      getCached<AccountLink>(id);

  /// Updates properties of the [AccountLink] document with [id] with {"fieldName": VALUE, ...}
  Future<void> updateAccountLink(String id, Map<String, dynamic> updates) =>
      $update<AccountLink>(id, updates);

  /// Opens a stream of the [AccountLink] document with [id]
  Stream<AccountLink?> streamAccountLink(String id) => $stream<AccountLink>(id);

  /// Deletes the [AccountLink] document with [id]
  Future<void> deleteAccountLink(String id) => $delete<AccountLink>(id);

  /// Adds a new [AccountLink] document with a new id and returns the created model with the id set
  Future<AccountLink> addAccountLink(
    AccountLink value, {
    bool useULID = false,
  }) => $add<AccountLink>(value, useULID: useULID);

  /// Sets the [AccountLink] document with [id] atomically by getting first then setting.
  Future<void> setAccountLinkAtomic(
    String id,
    AccountLink Function(AccountLink?) txn,
  ) => $setAtomic<AccountLink>(id, txn);

  /// Ensures that the [AccountLink] document with [id] exists, if not it will be created with [or]
  Future<void> ensureAccountLinkExists(String id, AccountLink or) =>
      $ensureExists<AccountLink>(id, or);

  /// Gets a model instance of [AccountLink] bound with [id] that can be used to access child models
  /// without network io.
  AccountLink accountLinkModel(String id) => $model<AccountLink>(id);

  /// Modifies properties of the [AccountLink] document with [id] atomically.
  Future<void> modifyAccountLink({
    required String id,

    /// Replaces the value of [discordId] with a new value atomically.
    String? discordId,

    /// Removes the [discordId] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteDiscordId = false,

    /// Replaces the value of [discordUsername] with a new value atomically.
    String? discordUsername,

    /// Removes the [discordUsername] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteDiscordUsername = false,

    /// Replaces the value of [discordGlobalName] with a new value atomically.
    String? discordGlobalName,

    /// Removes the [discordGlobalName] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteDiscordGlobalName = false,

    /// Replaces the value of [discordAvatarHash] with a new value atomically.
    String? discordAvatarHash,

    /// Removes the [discordAvatarHash] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteDiscordAvatarHash = false,

    /// Changes (increment/decrement) [discordLinkedAt] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaDiscordLinkedAt,

    /// Replaces the value of [discordLinkedAt] with a new value atomically.
    int? discordLinkedAt,

    /// Removes the [discordLinkedAt] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteDiscordLinkedAt = false,

    /// Replaces the value of [bungieConnected] with a new value atomically.
    bool? bungieConnected,

    /// Removes the [bungieConnected] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteBungieConnected = false,

    /// Replaces the value of [bungieAccountId] with a new value atomically.
    String? bungieAccountId,

    /// Removes the [bungieAccountId] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteBungieAccountId = false,

    /// Replaces the value of [bungieDisplayName] with a new value atomically.
    String? bungieDisplayName,

    /// Removes the [bungieDisplayName] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteBungieDisplayName = false,

    /// Replaces the value of [bungieAvatarPath] with a new value atomically.
    String? bungieAvatarPath,

    /// Removes the [bungieAvatarPath] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteBungieAvatarPath = false,

    /// Replaces the value of [bungieMarathonMembershipId] with a new value atomically.
    String? bungieMarathonMembershipId,

    /// Removes the [bungieMarathonMembershipId] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteBungieMarathonMembershipId = false,

    /// Changes (increment/decrement) [bungieLinkedAt] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaBungieLinkedAt,

    /// Replaces the value of [bungieLinkedAt] with a new value atomically.
    int? bungieLinkedAt,

    /// Removes the [bungieLinkedAt] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteBungieLinkedAt = false,

    /// Replaces the value of [bungieRefreshCiphertext] with a new value atomically.
    String? bungieRefreshCiphertext,

    /// Removes the [bungieRefreshCiphertext] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteBungieRefreshCiphertext = false,

    /// Replaces the value of [bungieRefreshNonce] with a new value atomically.
    String? bungieRefreshNonce,

    /// Removes the [bungieRefreshNonce] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteBungieRefreshNonce = false,

    /// Changes (increment/decrement) [bungieRefreshExpiresAt] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaBungieRefreshExpiresAt,

    /// Replaces the value of [bungieRefreshExpiresAt] with a new value atomically.
    int? bungieRefreshExpiresAt,

    /// Removes the [bungieRefreshExpiresAt] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteBungieRefreshExpiresAt = false,

    /// Changes (increment/decrement) [updatedAt] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaUpdatedAt,

    /// Replaces the value of [updatedAt] with a new value atomically.
    int? updatedAt,

    /// Removes the [updatedAt] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteUpdatedAt = false,
    bool $z = false,
  }) => $update<AccountLink>(id, {
    if (discordId != null) 'discordId': discordId,
    if (deleteDiscordId) 'discordId': FieldValue.delete(),
    if (discordUsername != null) 'discordUsername': discordUsername,
    if (deleteDiscordUsername) 'discordUsername': FieldValue.delete(),
    if (discordGlobalName != null) 'discordGlobalName': discordGlobalName,
    if (deleteDiscordGlobalName) 'discordGlobalName': FieldValue.delete(),
    if (discordAvatarHash != null) 'discordAvatarHash': discordAvatarHash,
    if (deleteDiscordAvatarHash) 'discordAvatarHash': FieldValue.delete(),
    if (discordLinkedAt != null) 'discordLinkedAt': discordLinkedAt,
    if (deltaDiscordLinkedAt != null)
      'discordLinkedAt': FieldValue.increment(deltaDiscordLinkedAt),
    if (deleteDiscordLinkedAt) 'discordLinkedAt': FieldValue.delete(),
    if (bungieConnected != null) 'bungieConnected': bungieConnected,
    if (deleteBungieConnected) 'bungieConnected': FieldValue.delete(),
    if (bungieAccountId != null) 'bungieAccountId': bungieAccountId,
    if (deleteBungieAccountId) 'bungieAccountId': FieldValue.delete(),
    if (bungieDisplayName != null) 'bungieDisplayName': bungieDisplayName,
    if (deleteBungieDisplayName) 'bungieDisplayName': FieldValue.delete(),
    if (bungieAvatarPath != null) 'bungieAvatarPath': bungieAvatarPath,
    if (deleteBungieAvatarPath) 'bungieAvatarPath': FieldValue.delete(),
    if (bungieMarathonMembershipId != null)
      'bungieMarathonMembershipId': bungieMarathonMembershipId,
    if (deleteBungieMarathonMembershipId)
      'bungieMarathonMembershipId': FieldValue.delete(),
    if (bungieLinkedAt != null) 'bungieLinkedAt': bungieLinkedAt,
    if (deltaBungieLinkedAt != null)
      'bungieLinkedAt': FieldValue.increment(deltaBungieLinkedAt),
    if (deleteBungieLinkedAt) 'bungieLinkedAt': FieldValue.delete(),
    if (bungieRefreshCiphertext != null)
      'bungieRefreshCiphertext': bungieRefreshCiphertext,
    if (deleteBungieRefreshCiphertext)
      'bungieRefreshCiphertext': FieldValue.delete(),
    if (bungieRefreshNonce != null) 'bungieRefreshNonce': bungieRefreshNonce,
    if (deleteBungieRefreshNonce) 'bungieRefreshNonce': FieldValue.delete(),
    if (bungieRefreshExpiresAt != null)
      'bungieRefreshExpiresAt': bungieRefreshExpiresAt,
    if (deltaBungieRefreshExpiresAt != null)
      'bungieRefreshExpiresAt': FieldValue.increment(
        deltaBungieRefreshExpiresAt,
      ),
    if (deleteBungieRefreshExpiresAt)
      'bungieRefreshExpiresAt': FieldValue.delete(),
    if (updatedAt != null) 'updatedAt': updatedAt,
    if (deltaUpdatedAt != null)
      'updatedAt': FieldValue.increment(deltaUpdatedAt),
    if (deleteUpdatedAt) 'updatedAt': FieldValue.delete(),
  });
}
