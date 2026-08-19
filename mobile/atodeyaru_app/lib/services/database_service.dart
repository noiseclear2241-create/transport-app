import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// 端末内SQLite（sqflite）による永続化。
///
/// 個人情報・機密情報のリスクを避けるため、契約書・画像・動画・音声は
/// 一切保存しない。保存するのはユーザーが手入力した小容量の構造化データのみ（#8, #9, #46）。
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'atodeyaru.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE family_members (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            relation TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE contracts (
            id TEXT PRIMARY KEY,
            family_member_id TEXT NOT NULL,
            type TEXT NOT NULL,
            carrier TEXT NOT NULL,
            carrier_other TEXT,
            contract_date TEXT NOT NULL,
            contract_number TEXT,
            monthly_fee_yen INTEGER,
            memo TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE options (
            id TEXT PRIMARY KEY,
            contract_id TEXT NOT NULL,
            name TEXT NOT NULL,
            monthly_fee_yen INTEGER,
            start_date TEXT NOT NULL,
            free_period TEXT NOT NULL,
            free_period_custom_months INTEGER,
            cancellation_check_date TEXT,
            memo TEXT,
            notify_days_before TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE benefits (
            id TEXT PRIMARY KEY,
            contract_id TEXT NOT NULL,
            name TEXT NOT NULL,
            amount_yen INTEGER,
            type TEXT NOT NULL,
            application_required INTEGER NOT NULL,
            application_start_date TEXT,
            application_deadline TEXT,
            expected_receipt_date TEXT,
            condition TEXT,
            memo TEXT,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE devices (
            id TEXT PRIMARY KEY,
            family_member_id TEXT NOT NULL,
            contract_id TEXT,
            name TEXT NOT NULL,
            maker TEXT,
            purchase_date TEXT,
            use_start_date TEXT,
            purchase_method TEXT NOT NULL,
            price_yen INTEGER,
            installment_count INTEGER,
            monthly_payment_yen INTEGER,
            return_program_name TEXT,
            return_period TEXT NOT NULL,
            return_period_custom_months INTEGER,
            return_check_date TEXT,
            return_deadline TEXT,
            memo TEXT,
            notify_days_before TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE checklist_items (
            id TEXT PRIMARY KEY,
            device_id TEXT NOT NULL,
            label TEXT NOT NULL,
            checked INTEGER NOT NULL,
            sort_order INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            family_member_id TEXT NOT NULL,
            title TEXT NOT NULL,
            type TEXT NOT NULL,
            due_date TEXT NOT NULL,
            source_type TEXT,
            source_id TEXT,
            subtitle TEXT,
            status TEXT NOT NULL,
            completed_at TEXT,
            snoozed_until TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_options_contract ON options(contract_id)');
        await db.execute('CREATE INDEX idx_benefits_contract ON benefits(contract_id)');
        await db.execute('CREATE INDEX idx_devices_contract ON devices(contract_id)');
        await db.execute('CREATE INDEX idx_checklist_device ON checklist_items(device_id)');
        await db.execute('CREATE INDEX idx_tasks_due ON tasks(due_date)');
        await db.execute('CREATE INDEX idx_tasks_source ON tasks(source_type, source_id)');
      },
    );
  }

  // ---- family_members ----
  Future<void> upsertFamilyMember(FamilyMember m) async {
    final db = await database;
    await db.insert('family_members', m.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<FamilyMember>> getFamilyMembers() async {
    final db = await database;
    final rows = await db.query('family_members', orderBy: 'created_at ASC');
    return rows.map(FamilyMember.fromMap).toList();
  }

  Future<void> deleteFamilyMember(String id) async {
    final db = await database;
    await db.delete('family_members', where: 'id = ?', whereArgs: [id]);
  }

  // ---- contracts ----
  Future<void> upsertContract(Contract c) async {
    final db = await database;
    await db.insert('contracts', c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Contract>> getContracts({String? familyMemberId}) async {
    final db = await database;
    final rows = await db.query(
      'contracts',
      where: familyMemberId == null ? null : 'family_member_id = ?',
      whereArgs: familyMemberId == null ? null : [familyMemberId],
      orderBy: 'contract_date DESC',
    );
    return rows.map(Contract.fromMap).toList();
  }

  Future<Contract?> getContract(String id) async {
    final db = await database;
    final rows = await db.query('contracts', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Contract.fromMap(rows.first);
  }

  Future<void> deleteContract(String id) async {
    final db = await database;
    // 関連タスクの削除には子レコードのIDが必要なため、削除前に取得しておく
    // （バッチ内で先にoptions/benefitsを消すと、後続のサブクエリが空になってしまう）。
    final optionIds = (await db.query('options', columns: ['id'], where: 'contract_id = ?', whereArgs: [id]))
        .map((r) => r['id'] as String)
        .toList();
    final benefitIds = (await db.query('benefits', columns: ['id'], where: 'contract_id = ?', whereArgs: [id]))
        .map((r) => r['id'] as String)
        .toList();

    final batch = db.batch();
    batch.delete('contracts', where: 'id = ?', whereArgs: [id]);
    batch.delete('options', where: 'contract_id = ?', whereArgs: [id]);
    batch.delete('benefits', where: 'contract_id = ?', whereArgs: [id]);
    for (final optionId in optionIds) {
      batch.delete('tasks', where: 'source_type = ? AND source_id = ?', whereArgs: ['option', optionId]);
    }
    for (final benefitId in benefitIds) {
      batch.delete('tasks',
          where: '(source_type = ? OR source_type = ?) AND source_id = ?',
          whereArgs: ['benefit_application', 'benefit_receipt', benefitId]);
    }
    await batch.commit(noResult: true);
  }

  // ---- options ----
  Future<void> upsertOption(ContractOption o) async {
    final db = await database;
    await db.insert('options', o.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ContractOption>> getOptions({String? contractId}) async {
    final db = await database;
    final rows = await db.query(
      'options',
      where: contractId == null ? null : 'contract_id = ?',
      whereArgs: contractId == null ? null : [contractId],
      orderBy: 'cancellation_check_date ASC',
    );
    return rows.map(ContractOption.fromMap).toList();
  }

  Future<void> deleteOption(String id) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('options', where: 'id = ?', whereArgs: [id]);
    batch.delete('tasks', where: 'source_type = ? AND source_id = ?', whereArgs: ['option', id]);
    await batch.commit(noResult: true);
  }

  // ---- benefits ----
  Future<void> upsertBenefit(Benefit b) async {
    final db = await database;
    await db.insert('benefits', b.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Benefit>> getBenefits({String? contractId}) async {
    final db = await database;
    final rows = await db.query(
      'benefits',
      where: contractId == null ? null : 'contract_id = ?',
      whereArgs: contractId == null ? null : [contractId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Benefit.fromMap).toList();
  }

  Future<void> deleteBenefit(String id) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('benefits', where: 'id = ?', whereArgs: [id]);
    batch.delete('tasks', where: '(source_type = ? OR source_type = ?) AND source_id = ?',
        whereArgs: ['benefit_application', 'benefit_receipt', id]);
    await batch.commit(noResult: true);
  }

  // ---- devices ----
  Future<void> upsertDevice(Device d) async {
    final db = await database;
    await db.insert('devices', d.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Device>> getDevices({String? familyMemberId}) async {
    final db = await database;
    final rows = await db.query(
      'devices',
      where: familyMemberId == null ? null : 'family_member_id = ?',
      whereArgs: familyMemberId == null ? null : [familyMemberId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Device.fromMap).toList();
  }

  Future<void> deleteDevice(String id) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('devices', where: 'id = ?', whereArgs: [id]);
    batch.delete('checklist_items', where: 'device_id = ?', whereArgs: [id]);
    batch.delete('tasks', where: 'source_type = ? AND source_id = ?', whereArgs: ['device_return', id]);
    await batch.commit(noResult: true);
  }

  // ---- checklist_items ----
  Future<void> upsertChecklistItem(ChecklistItem item) async {
    final db = await database;
    await db.insert('checklist_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChecklistItem>> getChecklistItems(String deviceId) async {
    final db = await database;
    final rows = await db.query('checklist_items',
        where: 'device_id = ?', whereArgs: [deviceId], orderBy: 'sort_order ASC');
    return rows.map(ChecklistItem.fromMap).toList();
  }

  // ---- tasks ----
  Future<void> upsertTask(TaskItem t) async {
    final db = await database;
    await db.insert('tasks', t.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TaskItem>> getTasks({String? familyMemberId, TaskStatus? status}) async {
    final db = await database;
    final conditions = <String>[];
    final args = <Object?>[];
    if (familyMemberId != null) {
      conditions.add('family_member_id = ?');
      args.add(familyMemberId);
    }
    if (status != null) {
      conditions.add('status = ?');
      args.add(status.value);
    }
    final rows = await db.query(
      'tasks',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'due_date ASC',
    );
    return rows.map(TaskItem.fromMap).toList();
  }

  Future<List<TaskItem>> getTasksBySource(String sourceType, String sourceId) async {
    final db = await database;
    final rows = await db.query('tasks',
        where: 'source_type = ? AND source_id = ?', whereArgs: [sourceType, sourceId]);
    return rows.map(TaskItem.fromMap).toList();
  }

  Future<void> deleteTasksBySource(String sourceType, String sourceId) async {
    final db = await database;
    await db.delete('tasks', where: 'source_type = ? AND source_id = ?', whereArgs: [sourceType, sourceId]);
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  /// アカウント削除（#64）：端末内の全データを削除する。
  Future<void> deleteAllData() async {
    final db = await database;
    final batch = db.batch();
    for (final table in [
      'tasks',
      'checklist_items',
      'benefits',
      'options',
      'devices',
      'contracts',
      'family_members',
    ]) {
      batch.delete(table);
    }
    await batch.commit(noResult: true);
  }
}
