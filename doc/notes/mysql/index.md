# MySQL

## Record

Dynamic格式：可变字段长度列表 + Null值列表 + 行首信息 + row_id + trx_id + roll_pointer + 列1 + 列2 + ...... 列N

## 事务

ACID

脏读、不可重复读、幻读

MVCC（多版本并发控制）：使用了行数据的隐藏列（trx_id + roll_pointer）构建的`版本链`

ReadView（creator_trx_id, min_trx_id, max_trx_id, m_ids）

* m_ids ：指的是在创建 Read View 时，当前数据库中「活跃事务」的事务 id 列表，注意是一个列表，“活跃事务”指的就是，启动了但还没提交的事务。
* min_trx_id ：指的是在创建 Read View 时，当前数据库中「活跃事务」中事务 id 最小的事务，也就是 m_ids 的最小值。
* max_trx_id ：这个并不是 m_ids 的最大值，而是创建 Read View 时当前数据库中应该给下一个事务的 id 值，也就是全局事务中最大的事务
  id 值 + 1；
* creator_trx_id ：指的是创建该 Read View 的事务的事务 id。

read_committed：每次读时都创建 ReadView

repeatable_read：ReadView 仅在事务开始时创建一次

* 如果记录的 trx_id 值小于 Read View 中的 min_trx_id 值，表示这个版本的记录是在创建 Read View
  前已经提交的事务生成的，所以该版本的记录对当前事务可见。
* 如果记录的 trx_id 值大于等于 Read View 中的 max_trx_id 值，表示这个版本的记录是在创建 Read View
  后才启动的事务生成的，所以该版本的记录对当前事务不可见。
* 如果记录的 trx_id 值在 Read View 的 min_trx_id 和 max_trx_id 之间，需要判断 trx_id 是否在 m_ids 列表中：
    * 如果记录的 trx_id 在 m_ids 列表中，表示生成该版本记录的活跃事务依然活跃着（还没提交事务），所以该版本的记录对当前事务不可见。
    * 如果记录的 trx_id 不在 m_ids列表中，表示生成该版本记录的活跃事务已经被提交，所以该版本的记录对当前事务可见。

##

buffer pool

redo log buffer

binlog cache

redo log 写 page cache，是否同步刷盘可设置

binlog cache 写 page cache，是否同步刷盘可设置

两阶段提交，保证 redo log 与 binlog 一致，以 binlog 写成功为事务提交成功的标识，因为 binlog 写成功了，就意味着能在 binlog
中查找到与 redo log 相同的 XID（事务ID）。

事务没提交的时候，redo log 也是可能被持久化到磁盘的。这种情况 mysql 重启会进行回滚操作。

MySQL 引入了 binlog 组提交（group commit）机制，当有多个事务提交的时候，会将多个 binlog 刷盘操作合并成一个，从而减少磁盘 I/O
的次数。

