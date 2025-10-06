/* Copyright (c) 2000, 2011, Oracle and/or its affiliates. All rights reserved.
   Copyright (c) 2017, MariaDB Corporation.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1335  USA */

#ifndef SQL_ERROR_H
#define SQL_ERROR_H

#include "sql_list.h" 	/* Sql_alloc, MEM_ROOT, list */
#include "sql_type_int.h" // Longlong_hybrid
#include "sql_string.h"                        /* String */
#include "sql_plist.h" /* I_P_List */
#include "mysql_com.h" /* MYSQL_ERRMSG_SIZE */
#include "my_time.h"   /* MYSQL_TIME */
#include "decimal.h"

class THD;
class my_decimal;
class sp_condition_value;

/* Types of LOG warnings, used by note_verbosity */

#define NOTE_VERBOSITY_NORMAL             (1U << 0)
/* Show warnings about keys parts that cannot be used */
#define NOTE_VERBOSITY_UNUSABLE_KEYS      (1U << 1)
/* Show warnings in explain for key parts that cannot be used */
#define NOTE_VERBOSITY_EXPLAIN            (1U << 2)

///////////////////////////////////////////////////////////////////////////

class Sql_state
{
protected:
  /**
    This member is always NUL terminated.
  */
  char m_sqlstate[SQLSTATE_LENGTH + 1];
public:
  Sql_state()
  {
    memset(m_sqlstate, 0, sizeof(m_sqlstate));
  }

  Sql_state(const char *sqlstate)
  {
    set_sqlstate(sqlstate);
  }

  const char* get_sqlstate() const
  { return m_sqlstate; }

  void set_sqlstate(const Sql_state *other)
  {
    *this= *other;
  }
  void set_sqlstate(const char *sqlstate)
  {
    memcpy(m_sqlstate, sqlstate, SQLSTATE_LENGTH);
    m_sqlstate[SQLSTATE_LENGTH]= '\0';
  }
  bool eq(const Sql_state *other) const
  {
    return strcmp(m_sqlstate, other->m_sqlstate) == 0;
  }

  bool has_sql_state() const { return m_sqlstate[0] != '\0'; }

  /**
    Checks if this SQL state defines a WARNING condition.
    Note: m_sqlstate must contain a valid SQL-state.

    @retval true if this SQL state defines a WARNING condition.
    @retval false otherwise.
  */
  inline bool is_warning() const
  { return m_sqlstate[0] == '0' && m_sqlstate[1] == '1'; }


  /**
    Checks if this SQL state defines a NOT FOUND condition.
    Note: m_sqlstate must contain a valid SQL-state.

    @retval true if this SQL state defines a NOT FOUND condition.
    @retval false otherwise.
  */
  inline bool is_not_found() const
  { return m_sqlstate[0] == '0' && m_sqlstate[1] == '2'; }


  /**
    Checks if this SQL state defines an EXCEPTION condition.
    Note: m_sqlstate must contain a valid SQL-state.

    @retval true if this SQL state defines an EXCEPTION condition.
    @retval false otherwise.
  */
  inline bool is_exception() const
  { return m_sqlstate[0] != '0' || m_sqlstate[1] > '2'; }

};


class Sql_state_errno: public Sql_state
{
protected:
  /**
    MySQL extension, MYSQL_ERRNO condition item.
    SQL error number. One of ER_ codes from share/errmsg.txt.
    Set by set_error_status.
  */
  uint m_sql_errno;

public:
  Sql_state_errno()
   :m_sql_errno(0)
  { }
  Sql_state_errno(uint sql_errno)
   :m_sql_errno(sql_errno)
  { }
  Sql_state_errno(uint sql_errno, const char *sql_state)
   :Sql_state(sql_state),
    m_sql_errno(sql_errno)
  { }
  /**
    Get the SQL_ERRNO of this condition.
    @return the sql error number condition item.
  */
  uint get_sql_errno() const
  { return m_sql_errno; }

  void set(uint sql_errno, const char *sqlstate)
  {
    m_sql_errno= sql_errno;
    set_sqlstate(sqlstate);
  }
  void clear()
  {
    m_sql_errno= 0;
  }
};


class Sql_state_errno_level: public Sql_state_errno
{
public:
  /*
    Enumeration value describing the severity of the error.

    Note that these enumeration values must correspond to the indices
    of the sql_print_message_handlers array.
  */
  enum enum_warning_level
  { WARN_LEVEL_NOTE, WARN_LEVEL_WARN, WARN_LEVEL_ERROR, WARN_LEVEL_END};

protected:
  /** Severity (error, warning, note) of this condition. */
  enum_warning_level m_level;

  void assign_defaults(const Sql_state_errno *value);

public:
  /**
    Get the error level of this condition.
    @return the error level condition item.
  */
  enum_warning_level get_level() const
  { return m_level; }

   Sql_state_errno_level()
    :m_level(WARN_LEVEL_ERROR)
  { }

  Sql_state_errno_level(uint sqlerrno, const char* sqlstate,
                         enum_warning_level level)
   :Sql_state_errno(sqlerrno, sqlstate),
    m_level(level)
  { }
  Sql_state_errno_level(const Sql_state_errno &state_errno,
                         enum_warning_level level)
   :Sql_state_errno(state_errno),
    m_level(level)
  { }
  void clear()
  {
    m_level= WARN_LEVEL_ERROR;
    Sql_state_errno::clear();
  }
};


/*
  class Sql_user_condition_identity.
  Instances of this class uniquely idetify user defined conditions (EXCEPTION).

    SET sql_mode=ORACLE;
    CREATE PROCEDURE p1
    AS
      a EXCEPTION;
    BEGIN
      RAISE a;
    EXCEPTION
      WHEN a THEN NULL;
    END;

  Currently a user defined condition is identified by a pointer to
  its parse time sp_condition_value instance. This can change when
  we add packages. See MDEV-10591.
*/
class Sql_user_condition_identity
{
protected:
  const sp_condition_value *m_user_condition_value;
public:
  Sql_user_condition_identity()
   :m_user_condition_value(NULL)
  { }
  Sql_user_condition_identity(const sp_condition_value *value)
   :m_user_condition_value(value)
  { }
  const sp_condition_value *get_user_condition_value() const
  { return m_user_condition_value; }

  void set(const Sql_user_condition_identity &identity)
  {
    *this= identity;
  }
  void clear()
  {
    m_user_condition_value= NULL;
  }
};


/**
  class Sql_condition_identity.
  Instances of this class uniquely identify conditions
  (including user-defined exceptions for sql_mode=ORACLE)
  and store everything that is needed for handler search
  purposes in sp_pcontext::find_handler().
*/
class Sql_condition_identity: public Sql_state_errno_level,
                              public Sql_user_condition_identity
{
public:
  Sql_condition_identity() = default;
  Sql_condition_identity(const Sql_state_errno_level &st,
                         const Sql_user_condition_identity &ucid)
   :Sql_state_errno_level(st),
    Sql_user_condition_identity(ucid)
  { }
  Sql_condition_identity(const Sql_state_errno &st,
                         enum_warning_level level,
                         const Sql_user_condition_identity &ucid)
   :Sql_state_errno_level(st, level),
    Sql_user_condition_identity(ucid)
  { }
  Sql_condition_identity(uint sqlerrno,
                         const char* sqlstate,
                         enum_warning_level level,
                         const Sql_user_condition_identity &ucid)
    :Sql_state_errno_level(sqlerrno, sqlstate, level),
     Sql_user_condition_identity(ucid)
  { }
  void clear()
  {
    Sql_state_errno_level::clear();
    Sql_user_condition_identity::clear();
  }
};


class Sql_condition_items
{
protected:
  /** SQL CLASS_ORIGIN condition item. */
  String m_class_origin;

  /** SQL SUBCLASS_ORIGIN condition item. */
  String m_subclass_origin;

  /** SQL CONSTRAINT_CATALOG condition item. */
  String m_constraint_catalog;

  /** SQL CONSTRAINT_SCHEMA condition item. */
  String m_constraint_schema;

  /** SQL CONSTRAINT_NAME condition item. */
  String m_constraint_name;

  /** SQL CATALOG_NAME condition item. */
  String m_catalog_name;

  /** SQL SCHEMA_NAME condition item. */
  String m_schema_name;

  /** SQL TABLE_NAME condition item. */
  String m_table_name;

  /** SQL COLUMN_NAME condition item. */
  String m_column_name;

  /** SQL CURSOR_NAME condition item. */
  String m_cursor_name;

  Sql_condition_items()
   :m_class_origin((const char*) NULL, 0, & my_charset_utf8mb3_bin),
    m_subclass_origin((const char*) NULL, 0, & my_charset_utf8mb3_bin),
    m_constraint_catalog((const char*) NULL, 0, & my_charset_utf8mb3_bin),
    m_constraint_schema((const char*) NULL, 0, & my_charset_utf8mb3_bin),
    m_constraint_name((const char*) NULL, 0, & my_charset_utf8mb3_bin),
    m_catalog_name((const char*) NULL, 0, & my_charset_utf8mb3_bin),
    m_schema_name((const char*) NULL, 0, & my_charset_utf8mb3_bin),
    m_table_name((const char*) NULL, 0, & my_charset_utf8mb3_bin),
    m_column_name((const char*) NULL, 0, & my_charset_utf8mb3_bin),
    m_cursor_name((const char*) NULL, 0, & my_charset_utf8mb3_bin)
  { }

  void clear()
  {
    m_class_origin.length(0);
    m_subclass_origin.length(0);
    m_constraint_catalog.length(0);
    m_constraint_schema.length(0);
    m_constraint_name.length(0);
    m_catalog_name.length(0);
    m_schema_name.length(0);
    m_table_name.length(0);
    m_column_name.length(0);
    m_cursor_name.length(0);
  }
};


/**
  Representation of a SQL condition.
  A SQL condition can be a completion condition (note, warning),
  or an exception condition (error, not found).
*/
class Sql_condition : public Sql_alloc,
                      public Sql_condition_identity,
                      public Sql_condition_items
{
public:

  /**
    Convert a bitmask consisting of MYSQL_TIME_{NOTE|WARN}_XXX bits
    to WARN_LEVEL_XXX
  */
  static enum_warning_level time_warn_level(uint warnings)
  {
    return MYSQL_TIME_WARN_HAVE_WARNINGS(warnings) ?
           WARN_LEVEL_WARN : WARN_LEVEL_NOTE;
  }

  /**
    Get the MESSAGE_TEXT of this condition.
    @return the message text.
  */
  const char* get_message_text() const;

  /**
    Get the MESSAGE_OCTET_LENGTH of this condition.
    @return the length in bytes of the message text.
  */
  int get_message_octet_length() const;

private:
  /*
    The interface of Sql_condition is mostly private, by design,
    so that only the following code:
    - various raise_error() or raise_warning() methods in class THD,
    - the implementation of SIGNAL / RESIGNAL / GET DIAGNOSTICS
    - catch / re-throw of SQL conditions in stored procedures (sp_rcontext)
    is allowed to create / modify a SQL condition.
    Enforcing this policy prevents confusion, since the only public
    interface available to the rest of the server implementation
    is the interface offered by the THD methods (THD::raise_error()),
    which should be used.
  */
  friend class THD;
  friend class Warning_info;
  friend class Sql_cmd_common_signal;
  friend class Sql_cmd_signal;
  friend class Sql_cmd_resignal;
  friend class sp_rcontext;
  friend class Condition_information_item;

  /**
    Default constructor.
    This constructor is usefull when allocating arrays.
    Note that the init() method should be called to complete the Sql_condition.
  */
  Sql_condition()
   :m_mem_root(NULL)
  { }

  /**
    Complete the Sql_condition initialisation.
    @param mem_root The memory root to use for the condition items
    of this condition
  */
  void init(MEM_ROOT *mem_root)
  {
    DBUG_ASSERT(mem_root != NULL);
    DBUG_ASSERT(m_mem_root == NULL);
    m_mem_root= mem_root;
  }

  /**
    Constructor.
    @param mem_root The memory root to use for the condition items
    of this condition
  */
  Sql_condition(MEM_ROOT *mem_root)
   :m_mem_root(mem_root)
  {
    DBUG_ASSERT(mem_root != NULL);
  }

  Sql_condition(MEM_ROOT *mem_root, const Sql_user_condition_identity &ucid)
   :Sql_condition_identity(Sql_state_errno_level(), ucid),
    m_mem_root(mem_root)
  {
    DBUG_ASSERT(mem_root != NULL);
  }
  /**
    Constructor for a fixed message text.
    @param mem_root - memory root
    @param value    - the error number and the sql state for this condition
    @param level    - the error level for this condition
    @param msg      - the message text for this condition
  */
  Sql_condition(MEM_ROOT *mem_root,
                const Sql_condition_identity &value,
                const char *msg)
   :Sql_condition_identity(value),
    m_mem_root(mem_root)
  {
    DBUG_ASSERT(mem_root != NULL);
    DBUG_ASSERT(value.get_sql_errno() != 0);
    DBUG_ASSERT(msg != NULL);
    set_builtin_message_text(msg);
  }

  /** Destructor. */
  ~Sql_condition() = default;

  /**
    Copy optional condition items attributes.
    @param cond the condition to copy.
  */
  void copy_opt_attributes(const Sql_condition *cond);

  /**
    Set the condition message test.
    @param str Message text, expressed in the character set derived from
    the server --language option
  */
  void set_builtin_message_text(const char* str);

  /** Set the CLASS_ORIGIN of this condition. */
  void set_class_origin();

  /** Set the SUBCLASS_ORIGIN of this condition. */
  void set_subclass_origin();

  /**
    Assign the condition items 'MYSQL_ERRNO', 'level' and 'MESSAGE_TEXT'
    default values of a condition.
    @param thd   - current thread, to access to localized error messages
    @param from  - copy condition items from here (can be NULL)
  */
  void assign_defaults(THD *thd, const Sql_state_errno *from);

  /**
    Clear this SQL condition.
  */
  void clear()
  {
    Sql_condition_identity::clear();
    Sql_condition_items::clear();
    m_message_text.length(0);
  }

private:
  /** Message text, expressed in the character set implied by --language. */
  String m_message_text;

  /** Pointers for participating in the list of conditions. */
  Sql_condition *next_in_wi;
  Sql_condition **prev_in_wi;

  /** Memory root to use to hold condition item values. */
  MEM_ROOT *m_mem_root;
};

///////////////////////////////////////////////////////////////////////////

/**
  Information about warnings of the current connection.
*/
class Warning_info
{
  /** The type of the counted and doubly linked list of conditions. */
  typedef I_P_List<Sql_condition,
                   I_P_List_adapter<Sql_condition,
                                    &Sql_condition::next_in_wi,
                                    &Sql_condition::prev_in_wi>,
                   I_P_List_counter,
                   I_P_List_fast_push_back<Sql_condition> >
          Sql_condition_list;

  /** A memory root to allocate warnings and errors */
  MEM_ROOT           m_warn_root;

  /** List of warnings of all severities (levels). */
  Sql_condition_list   m_warn_list;

  /** A break down of the number of warnings per severity (level). */
  uint	             m_warn_count[(uint) Sql_condition::WARN_LEVEL_END];

  /**
    The number of warnings of the current statement. Warning_info
    life cycle differs from statement life cycle -- it may span
    multiple statements. In that case we get
    m_current_statement_warn_count 0, whereas m_warn_list is not empty.
  */
  uint	             m_current_statement_warn_count;

  /*
    Row counter, to print in errors and warnings. Not increased in
    create_sort_index(); may differ from examined_row_count.
  */
  ulong              m_current_row_for_warning;

  /** Used to optionally clear warnings only once per statement. */
  ulonglong          m_warn_id;

  /**
    A pointer to an element of m_warn_list. It determines SQL-condition
    instance which corresponds to the error state in Diagnostics_area.
  
    This is needed for properly processing SQL-conditions in SQL-handlers.
    When an SQL-handler is found for the current error state in Diagnostics_area,
    this pointer is needed to remove the corresponding SQL-condition from the
    Warning_info list.
  
    @note m_error_condition might be NULL in the following cases:
       - Diagnostics_area set to fatal error state (like OOM);
       - Max number of Warning_info elements has been reached (thus, there is
         no corresponding SQL-condition object in Warning_info).
  */
  const Sql_condition *m_error_condition;

  /** Indicates if push_warning() allows unlimited number of warnings. */
  bool               m_allow_unlimited_warnings;
  bool		     initialized;    /* Set to 1 if init() has been called */

  /** Read only status. */
  bool m_read_only;

  /** Pointers for participating in the stack of Warning_info objects. */
  Warning_info *m_next_in_da;
  Warning_info **m_prev_in_da;

  List<Sql_condition> m_marked_sql_conditions;

public:
  Warning_info(ulonglong warn_id_arg, bool allow_unlimited_warnings,
               bool initialized);
  ~Warning_info();
  /* Allocate memory for structures */
  void init();
  void free_memory();

private:
  Warning_info(const Warning_info &rhs); /* Not implemented */
  Warning_info& operator=(const Warning_info &rhs); /* Not implemented */

  /**
    Checks if Warning_info contains SQL-condition with the given message.

    @param message_str    Message string.
    @param message_length Length of message string.

    @return true if the Warning_info contains an SQL-condition with the given
    message.
  */
  bool has_sql_condition(const char *message_str, size_t message_length) const;

  /**
    Checks if Warning_info contains SQL-condition with the given error id

    @param sql_errno SQL-condition error number

    @return true if the Warning_info contains an SQL-condition with the given
    error id.
  */
  bool has_sql_condition(uint sql_errno) const;

  /**
    Reset the warning information. Clear all warnings,
    the number of warnings, reset current row counter
    to point to the first row.

    @param new_id new Warning_info id.
  */
  void clear(ulonglong new_id);

  /**
    Only clear warning info if haven't yet done that already
    for the current query. Allows to be issued at any time
    during the query, without risk of clearing some warnings
    that have been generated by the current statement.

    @todo: This is a sign of sloppy coding. Instead we need to
    designate one place in a statement life cycle where we call
    Warning_info::clear().

    @param query_id Current query id.
  */
  void opt_clear(ulonglong query_id)
  {
    if (query_id != m_warn_id)
      clear(query_id);
  }

  /**
    Concatenate the list of warnings.

    It's considered tolerable to lose an SQL-condition in case of OOM-error,
    or if the number of SQL-conditions in the Warning_info reached top limit.

    @param thd    Thread context.
    @param source Warning_info object to copy SQL-conditions from.
  */
  void append_warning_info(THD *thd, const Warning_info *source);

  /**
    Reset between two COM_ commands. Warnings are preserved
    between commands, but statement_warn_count indicates
    the number of warnings of this particular statement only.
  */
  void reset_for_next_command()
  { m_current_statement_warn_count= 0; }

  /**
    Mark active SQL-conditions for later removal.
    This is done to simulate stacked DAs for HANDLER statements.
  */
  void mark_sql_conditions_for_removal();

  /**
    Unmark SQL-conditions, which were marked for later removal.
    This is done to simulate stacked DAs for HANDLER statements.
  */
  void unmark_sql_conditions_from_removal()
  { m_marked_sql_conditions.empty(); }

  /**
    Remove SQL-conditions that are marked for deletion.
    This is done to simulate stacked DAs for HANDLER statements.
  */
  void remove_marked_sql_conditions();

  /**
    Check if the given SQL-condition is marked for removal in this Warning_info
    instance.

    @param cond the SQL-condition.

    @retval true if the given SQL-condition is marked for removal in this
                 Warning_info instance.
    @retval false otherwise.
  */
  bool is_marked_for_removal(const Sql_condition *cond) const;

  /**
    Mark a single SQL-condition for removal (add the given SQL-condition to the
    removal list of this Warning_info instance).
  */
  void mark_condition_for_removal(Sql_condition *cond)
  { m_marked_sql_conditions.push_back(cond, &m_warn_root); }

  /**
    Used for @@warning_count system variable, which prints
    the number of rows returned by SHOW WARNINGS.
  */
  ulong warn_count() const
  {
    /*
      This may be higher than warn_list.elements() if we have
      had more warnings than thd->variables.max_error_count.
    */
    return (m_warn_count[(uint) Sql_condition::WARN_LEVEL_NOTE] +
            m_warn_count[(uint) Sql_condition::WARN_LEVEL_ERROR] +
            m_warn_count[(uint) Sql_condition::WARN_LEVEL_WARN]);
  }

  /**
    The number of errors, or number of rows returned by SHOW ERRORS,
    also the value of session variable @@error_count.
  */
  ulong error_count() const
  { return m_warn_count[(uint) Sql_condition::WARN_LEVEL_ERROR]; }

  /**
    The number of conditions (errors, warnings and notes) in the list.
  */
  uint cond_count() const
  {
    return m_warn_list.elements();
  }

  /** Id of the warning information area. */
  ulonglong id() const { return m_warn_id; }

  /** Set id of the warning information area. */
  void id(ulonglong id_arg) { m_warn_id= id_arg; }

  /** Do we have any errors and warnings that we can *show*? */
  bool is_empty() const { return m_warn_list.is_empty(); }

  /** Increment the current row counter to point at the next row. */
  void inc_current_row_for_warning() { m_current_row_for_warning++; }

  /** Reset the current row counter. Start counting from the first row. */
  void reset_current_row_for_warning() { m_current_row_for_warning= 1; }

  ulong set_current_row_for_warning(ulong row)
  {
    ulong old_row= m_current_row_for_warning;
    m_current_row_for_warning= row;
    return old_row;
  }

  /** Return the current counter value. */
  ulong current_row_for_warning() const { return m_current_row_for_warning; }

  /** Return the number of warnings thrown by the current statement. */
  ulong current_statement_warn_count() const
  { return m_current_statement_warn_count; }

  /** Make sure there is room for the given number of conditions. */
  void reserve_space(THD *thd, uint count);

  /**
    Add a new SQL-condition to the current list and increment the respective
    counters.

    @param thd        Thread context.
    @param identity   SQL-condition identity
    @param msg        SQL-condition message.

    @return a pointer to the added SQL-condition.
  */
  Sql_condition *push_warning(THD *thd,
                              const Sql_condition_identity *identity,
                              const char* msg);

  /**
    Add a new SQL-condition to the current list and increment the respective
    counters.

    @param thd            Thread context.
    @param sql_condition  SQL-condition to copy values from.

    @return a pointer to the added SQL-condition.
  */
  Sql_condition *push_warning(THD *thd, const Sql_condition *sql_condition);

  /**
    Set the read only status for this statement area.
    This is a privileged operation, reserved for the implementation of
    diagnostics related statements, to enforce that the statement area is
    left untouched during execution.
    The diagnostics statements are:
    - SHOW WARNINGS
    - SHOW ERRORS
    - GET DIAGNOSTICS
    @param read_only the read only property to set.
  */
  void set_read_only(bool read_only_arg)
  { m_read_only= read_only_arg; }

  /**
    Read only status.
    @return the read only property.
  */
  bool is_read_only() const
  { return m_read_only; }

  /**
    @return SQL-condition, which corresponds to the error state in
    Diagnostics_area.

    @see m_error_condition.
  */
  const Sql_condition *get_error_condition() const
  { return m_error_condition; }

  /**
    Set SQL-condition, which corresponds to the error state in Diagnostics_area.

    @see m_error_condition.
  */
  void set_error_condition(const Sql_condition *error_condition)
  { m_error_condition= error_condition; }

  /**
    Reset SQL-condition, which corresponds to the error state in
    Diagnostics_area.

    @see m_error_condition.
  */
  void clear_error_condition()
  { m_error_condition= NULL; }

  // for:
  //   - m_next_in_da / m_prev_in_da
  //   - is_marked_for_removal()
  friend class Diagnostics_area;
};


extern size_t err_conv(char *buff, uint to_length, const char *from,
                       uint from_length, CHARSET_INFO *from_cs);

class ErrBuff
{
protected:
  mutable char err_buffer[MYSQL_ERRMSG_SIZE];
public:
  ErrBuff()
  {
    err_buffer[0]= '\0';
  }
  const char *ptr() const { return err_buffer; }
  LEX_CSTRING set_longlong(const Longlong_hybrid &nr) const
  {
    int radix= nr.is_unsigned() ? 10 : -10;
    const char *end= longlong10_to_str(nr.value(), err_buffer, radix);
    DBUG_ASSERT(end >= err_buffer);
    return {err_buffer, (size_t) (end - err_buffer)};
  }
  LEX_CSTRING set_double(double nr) const
  {
    size_t length= my_gcvt(nr, MY_GCVT_ARG_DOUBLE,
                           sizeof(err_buffer), err_buffer, 0);
    return {err_buffer, length};
  }
  LEX_CSTRING set_decimal(const decimal_t *d) const
  {
    int length= sizeof(err_buffer);
    decimal2string(d, err_buffer, &length, 0, 0, ' ');
    DBUG_ASSERT(length >= 0);
    return {err_buffer, (size_t) length};
  }
  LEX_CSTRING set_str(const char *str, size_t len, CHARSET_INFO *cs) const
  {
    DBUG_ASSERT(len < UINT_MAX32);
    len= err_conv(err_buffer, (uint) sizeof(err_buffer), str, (uint) len, cs);
    return {err_buffer, len};
  }
  LEX_CSTRING set_mysql_time(const MYSQL_TIME *ltime) const
  {
    int length= my_TIME_to_str(ltime, err_buffer, AUTO_SEC_PART_DIGITS);
    DBUG_ASSERT(length >= 0);
    return {err_buffer, (size_t) length};
  }
};


class ErrConv: public ErrBuff
{
public:
  ErrConv() = default;
  virtual ~ErrConv() = default;
  virtual LEX_CSTRING lex_cstring() const= 0;
  inline const char *ptr() const
  {
    return lex_cstring().str;
  }
};

class ErrConvString : public ErrConv
{
  const char *str;
  size_t len;
  CHARSET_INFO *cs;
public:
  ErrConvString(const char *str_arg, size_t len_arg, CHARSET_INFO *cs_arg)
    : ErrConv(), str(str_arg), len(len_arg), cs(cs_arg) {}
  ErrConvString(const char *str_arg, CHARSET_INFO *cs_arg)
    : ErrConv(), str(str_arg), len(strlen(str_arg)), cs(cs_arg) {}
  ErrConvString(const String *s)
    : ErrConv(), str(s->ptr()), len(s->length()), cs(s->charset()) {}
  LEX_CSTRING lex_cstring() const override
  {
    return set_str(str, len, cs);
  }
};

class ErrConvInteger : public ErrConv, public Longlong_hybrid
{
public:
  ErrConvInteger(const Longlong_hybrid &nr)
   : ErrConv(), Longlong_hybrid(nr) { }
  LEX_CSTRING lex_cstring() const override
  {
    return set_longlong(static_cast<Longlong_hybrid>(*this));
  }
};

class ErrConvDouble: public ErrConv
{
  double num;
public:
  ErrConvDouble(double num_arg) : ErrConv(), num(num_arg) {}
  LEX_CSTRING lex_cstring() const override
  {
    return set_double(num);
  }
};

class ErrConvTime : public ErrConv
{
  const MYSQL_TIME *ltime;
public:
  ErrConvTime(const MYSQL_TIME *ltime_arg) : ErrConv(), ltime(ltime_arg) {}
  LEX_CSTRING lex_cstring() const override
  {
    return set_mysql_time(ltime);
  }
};

class ErrConvDecimal : public ErrConv
{
  const decimal_t *d;
public:
  ErrConvDecimal(const decimal_t *d_arg) : ErrConv(), d(d_arg) {}
  LEX_CSTRING lex_cstring() const override
  {
    return set_decimal(d);
  }
};

///////////////////////////////////////////////////////////////////////////

/**
  Stores status of the currently executed statement.
  Cleared at the beginning of the statement, and then
  can hold either OK, ERROR, or EOF status.
  Can not be assigned twice per statement.
*/

class Diagnostics_area: public Sql_state_errno,
                        public Sql_user_condition_identity
{
private:
  /** The type of the counted and doubly linked list of conditions. */
  typedef I_P_List<Warning_info,
                   I_P_List_adapter<Warning_info,
                                    &Warning_info::m_next_in_da,
                                    &Warning_info::m_prev_in_da>,
                   I_P_List_counter,
                   I_P_List_fast_push_back<Warning_info> >
          Warning_info_list;

public:
  /** Const iterator used to iterate through the warning list. */
  typedef Warning_info::Sql_condition_list::Const_Iterator
    Sql_condition_iterator;

  enum enum_diagnostics_status
  {
    /** The area is cleared at start of a statement. */
    DA_EMPTY= 0,
    /** Set whenever one calls my_ok(). */
    DA_OK,
    /** Set whenever one calls my_eof(). */
    DA_EOF,
    /** Set whenever one calls my_ok() in PS bulk mode. */
    DA_OK_BULK,
    /** Set whenever one calls my_eof() in PS bulk mode. */
    DA_EOF_BULK,
    /** Set whenever one calls my_error() or my_message(). */
    DA_ERROR,
    /** Set in case of a custom response, such as one from COM_STMT_PREPARE. */
    DA_DISABLED
  };

  void set_overwrite_status(bool can_overwrite_status)
  { m_can_overwrite_status= can_overwrite_status; }

  /** True if status information is sent to the client. */
  bool is_sent() const { return m_is_sent; }

  void set_is_sent(bool is_sent_arg) { m_is_sent= is_sent_arg; }

  void set_ok_status(ulonglong affected_rows,
                     ulonglong last_insert_id,
                     const char *message);

  void set_eof_status(THD *thd);

  void set_error_status(uint sql_errno);

  void set_error_status(uint sql_errno,
                        const char *message,
                        const char *sqlstate,
                        const Sql_user_condition_identity &ucid,
                        const Sql_condition *error_condition);

  void set_error_status(uint sql_errno,
                        const char *message,
                        const char *sqlstate,
                        const Sql_condition *error_condition)
  {
    set_error_status(sql_errno, message, sqlstate,
                     Sql_user_condition_identity(),
                     error_condition);
  }

  void disable_status();

  void reset_diagnostics_area();

  bool is_set() const { return m_status != DA_EMPTY; }

  bool is_error() const { return m_status == DA_ERROR; }

  bool is_eof() const { return m_status == DA_EOF; }

  bool is_ok() const { return m_status == DA_OK; }

  bool is_disabled() const { return m_status == DA_DISABLED; }

  void set_bulk_execution(bool bulk) { is_bulk_execution= bulk; }

  bool is_bulk_op() const { return is_bulk_execution; }

  enum_diagnostics_status status() const { return m_status; }

  const char *message() const
  {
    DBUG_ASSERT(m_status == DA_ERROR || m_status == DA_OK ||
                m_status == DA_OK_BULK || m_status == DA_EOF_BULK);
    return m_message;
  }


  uint sql_errno() const
  {
    DBUG_ASSERT(m_status == DA_ERROR);
    return Sql_state_errno::get_sql_errno();
  }

  const char* get_sqlstate() const
  { DBUG_ASSERT(m_status == DA_ERROR); return Sql_state::get_sqlstate(); }

  ulonglong affected_rows() const
  {
    DBUG_ASSERT(m_status == DA_OK || m_status == DA_OK_BULK);
    return m_affected_rows;
  }

  ulonglong last_insert_id() const
  {
    DBUG_ASSERT(m_status == DA_OK || m_status == DA_OK_BULK);
    return m_last_insert_id;
  }

  uint statement_warn_count() const
  {
    DBUG_ASSERT(m_status == DA_OK || m_status == DA_OK_BULK ||
                m_status == DA_EOF ||m_status == DA_EOF_BULK );
    return m_statement_warn_count;
  }

  uint unsafe_statement_warn_count() const
  {
    return m_statement_warn_count;
  }

  /**
    Get the current errno, state and id of the user defined condition
    and return them as Sql_condition_identity.
  */
  Sql_condition_identity get_error_condition_identity() const
  {
    DBUG_ASSERT(m_status == DA_ERROR);
    return Sql_condition_identity(*this /*Sql_state_errno*/,
                                  Sql_condition::WARN_LEVEL_ERROR,
                                  *this /*Sql_user_condition_identity*/);
  }

  /* Used to count any warnings pushed after calling set_ok_status(). */
  void increment_warning()
  {
    if (m_status != DA_EMPTY)
      m_statement_warn_count++;
  }

  Diagnostics_area(bool initialize);
  Diagnostics_area(ulonglong warning_info_id, bool allow_unlimited_warnings,
                   bool initialize);
  void init() { m_main_wi.init() ; }
  void free_memory() { m_main_wi.free_memory() ; }

  void push_warning_info(Warning_info *wi)
  { m_wi_stack.push_front(wi); }

  void pop_warning_info()
  {
    DBUG_ASSERT(m_wi_stack.elements() > 0);
    m_wi_stack.remove(m_wi_stack.front());
  }

  void set_warning_info_id(ulonglong id)
  { get_warning_info()->id(id); }

  ulonglong warning_info_id() const
  { return get_warning_info()->id(); }

  /**
    Compare giv�j��j���j�|�j���k��kT�k
��k�k��kO�k��k��kT�k$(�k$��k&��k&��k(:�k)o�k3[�k8��k<��k=��k>{�kA��kC��kC��kG��kK(�kK1�kK��kL �kM[�kSM�kUV�k^��kae�kf��kkp�kp�kt��k{��k���k���k���k���k�I�k���k��k�^�k�=�k���k�0�k���k���k���k�]�k���k�C�k���k�n�k��k��k��k���k��k�_�k��k�@�k۝�kܟ�k��k�s�k�3�k��k��k��k�Y�k�8�k�{�k���k�G�k���k�o�l6�l��l
	�l
,�ll�l�l��l��l��l�lU�l$^�l'��l(��l-Y�l/ �l1.�l1��l3��l3��l4��l:��l;l�l;��l<G�l=b�lA��lBI�lB��lC�lD2�lIN�lI��lM[�lVn�lW��lY��lZ��l[��l`��lbj�lj��lkT�lll�ll��ll��lp��lx��l{��l|i�ly�l{�l�>�l��l���l���l���l�S�l��l���l���l���l���l���l���l���l�J�l���l�]�l��l���lǬ�l���l���l�i�l�	�l�2�l���l���l��l�g�l�h�l��l�N�l�y�l�a�m�m��m��m
6�m�m��mo�m6�mb�m��m!�m!��m#��m$�m&��m()�m) �m,o�m.��m2\�m3 �m7��m9��mA��mI�mJ��mP��mQ�mW�m[��m]!�m_��mi�mi,�mjn�mp�mq]�mu�mwA�m���m�E�m�S�m���m�`�m�I�m��m���m���m�?�m�z�m��m���m���m���m�E�m���m���m�X�m���m�0�m���m�U�m���m�]�m�S�m�>�m���mϸ�m��m���m��mރ�m��m�)�m�h�m��m��m��m���m���m�C�m�4�n��n5�n��n^�n��n��n	��n��n��n��nS�nT�n��n,�n��n��n�n!@�n"��n&b�n*��n,��n-��n0q�n1��n5Z�n8��n8��n<��n@H�n@��nB�nC��nJ"�nJ��nQF�nS��nTX�n[\�n_0�n`��nb�nd��ng�ni@�ni��nl_�noF�noQ�no��nq�nvH�nw��ny��ny��nz��n|?�n}]�n���n�'�n���n���n�@�n�/�n�W�n���n���n�K�n���n�?�n���n���n��n�i�n���n�8�n���n�|�n���n���n��n�B�n���n���n���n���n��n���n�T�n��n�2�n�>�nҁ�nۥ�n���n��n�W�n�C�n���n��n���n� �n��n�h�n���n�k�n��o��oW�o~�oR�o��oy�o&�o'��o(B�o*��o+��o/i�o2w�o8��o9d�o=B�o=��o>��o?��oC4�oH�oJ��oK$�oLd�oL��oMq�oN��oR��o[=�o]?�o]}�o^��ocW�oc��om��om��oqV�ow"�oz��oz��o}Y�o~��o~��o���o�'�o�T�o�R�o���o�o�o���o���o���o�S�o���o���o�`�o���o���o��o���o��o�0�o�_�o���o���o�e�o͈�oσ�o�[�oЈ�o�1�o�b�oՕ�o׹�o��o���o��o���o�c�o�P�o���o�?�o���o�E�o�g�o���o���o�.�o���pM�p��p	B�p	R�py�p��p�p0�p��p��p!��p*
�p+Y�p8/�p>A�p?\�p?��pD��pK#�pN�pT;�pY��p]f�pb��pd��pe��pf��pj��pl��pu\�pvz�p{t�p{��p~+�p��p� �p���p���p���p�l�p��p��p�m�p�{�p���p���p�-�p���p���p�M�p�e�p�v�p��p���p���p�u�p�r�p���p���p���p�y�p�J�p�P�p���p�z�p���p��p�0�p��p���p���p�s�p�M�p��p��p�C�p�i�p���qV�q	U�q
^�q��q��q3�q��q��q��q��qf�q%�q%��q.:�q/ �q1��q1��q1��q2�q59�q:9�q>Z�qE��qE��qF(�qK1�qQ�qQ��q^��qa��qc��qeW�qe��qh��qn��qpd�qq�qqC�qsn�qs��qua�qw+�qw��qy��q{b�q~{�q~��q���q��q���q�o�q��q��q���q�F�q���q�K�q���q���q�Z�q���q���q���q�u�q���qɤ�q���q���q�(�qԄ�q�S�q�;�qצ�q٫�q�^�q�K�q�s�q��q� �q���q���rH�r��r��r��r��rq�rL�rk�rr�r��r��r��r!�r$B�r%(�r(��r+��r.��r15�r7m�r<.�r</�r=	�r=��r>��r?��rCj�rE|�rE��rF7�rG��rJ��rKD�rK��rNT�r]��r^��r^��rd��re��rmf�rn��rn��ro;�ro��ro��rs4�rs��rz#�r~��r�r�\�r�O�r�3�r���r���r���r���r���r��r���r���r�s�r���r�C�r���r��r���r���r���r�a�r���r��r�	�r�W�r��r��r�&�r���r�&�rƮ�rư�r��r���r�;�r�?�r�K�rӠ�r׾�r��r���r���r�T�rޟ�r��r��r��r� �r���r�~�r���s m�s)�s�s��sO�ss�s�s$�s��sE�s��s��s$��s)O�s,T�s,��s.�s2a�s2|�s5��s6��s<<�sE��sF��sHD�sJ�sL�sM�sO9�sQ��sS�sT/�sU��sVl�sW!�sW��s[0�s\��s]��s`c�sb��skY�sm��so��sqE�su�sx*�sy;�s|q�s���s�n�s���s���s�'�s���s�`�s���s�7�s���s���s�$�s���s�l�s�u�s��s���s���s��s���s���s���s�J�s���s���s�%�s���s��sҦ�s�`�s�e�s��s�q�s��s��s�7�s�T�s��s��s��s���s�N�s�l�s�	�t��t��tJ�t>�t��t��tT�t#��t$<�t%f�t%��t*��t+��t3��t5�t6��t6��t;��t=��t@�t@��tFp�tJ�tP��tQ��tR��tS��tT��tW��tW��tY�tb�tf��tiN�tt��tu��t|��t~��t�-�t���t���t�Y�t�|�t�?�t�*�t�{�t�g�t�r�t���t���t�^�t���t���t�5�t���t��t� �t�	�t��t���t��t�a�t�F�tռ�t��t�c�t�	�t��t���t�}�t��t��t��t���t�)�t���t���t���u�u��u	�u�u�u��u��u��u��u��u��up�u�uc�u �u"��u$��u&8�u)��u+��u07�u0M�u8}�u9��u=��u>f�u?B�uA��uJ��uO��uO��uP��uQ��uT �uT��uZ��u\�u]U�ub�ub��ue<�uf��uf��ulX�ul��uo��u���u��u���u���u�+�u�?�u��u�5�u�$�u���u���u�z�u���u���u��u�j�u�k�u���u�k�u�y�u���u�d�u��u�-�uʴ�u̳�u͎�u�V�u�X�uӅ�u���uւ�u�v�u׷�u�h�uߍ�u��u�'�u�h�u��u��u��u��u���u���u�n�v a�v ��v�v��v��v��v[�v	�vh�v��v��v�v��vr�vk�v��v0N�v0e�v0y�v9Z�vA
�vBH�vI:�vS��vS��vT;�vUO�vX��vY��v[x�v[��v\�v_$�v`��vdt�ve��vg��vl��vo��vp<�vs��v�^�v�$�v��v�C�v���v���v���v��v�;�v��v���v���v�H�v���v��v�z�v�m�v���vǄ�v��v���vӔ�vڑ�v�Z�v��v��v��v�s�v���v�>�v��v���v���v��v��v���v��v�i�v�B�w r�w��w*�w��w;�ws�wh�w��w��wC�w��w��w<�w�w��w!��w%|�w(��w)M�w*�w.��w0��w6g�w;��w<��w>V�w?�w?�wB�wE��wF��wR��wS��wTM�wUy�wW��wY��wZ��w["�w\ �w\��wb�wj�wo��wr�wr��wu��ww��w{��w}��w�	�w�E�w�q�w���w�>�w���w��w���w���w���w�g�w���w���w�k�w���w���w���w���w���w�m�w��w�T�w��w���w���w�R�w���w���w���w���w�)�w�5�w���w�D�w�+�w�;�w�s�w�,�w�`�w�\�w�r�w�f�w��w��w��w���w�D�w�b�w�5�w�(�w�b�w��w���w��w�F�x ��x.�x��x��xv�x��x��x��x&,�x*��x2�x2��x4+�x4��x5��x6�xE{�xG6�xG��xI��xJ��xL�xM��xQ��xR��xS��xV��xWi�xX�xZ�xZ��x^��xb$�xc7�xm��xp��xq��xr0�xr��xx��xy��xy��xz��x~�x��x���x���x���x���x��x�	�x�E�x���x���x�X�x�0�x���x�Z�x���x�1�x�O�x�	�x���x� �x��x�,�xҪ�x֪�x�-�x��x�:�x�T�x���x��x��x��x�d�x���x�-�x��x���x��x���x�=�x�Q�x���y��y��y��yT�yR�y ��y#@�y$��y%��y(w�y,T�y2��y2��y3&�y8��y8��y=]�yA,�yB��yC�yD
�yH��yK��yN��yQS�yT��yY��y[��y^�yl(�yr�yyD�yy��y|K�y}��y��y���y���y��y�!�y�*�y���y���y���y���y���y���y�o�y���y��y���y���y���y�2�y���y��yŹ�yǩ�y�=�y�R�y�p�yԆ�y���y�!�yۑ�y���y���y��y�"�y�f�y�;�y��y��y���z�z�z��z��z�z��z��z��z9�z��z��z�zL�z��z)s�z-��z2�z8�zL�zL�zQ5�zQ@�zQ��zR��zW��zYn�z]��z`��zc,�ze��zf��zt,�zt��zvf�zy�zy��z��z���z���z�S�z�u�z�.�z���z�n�z�_�z���z���z�=�z���z�*�z���z���z�.�z�`�z���z�(�z�B�z̈́�zͩ�z�#�z���z���z���zٔ�z�U�z�S�z��z���z�
�z��z�h�z�m�z���z���z�:�{ ��{ �{4�{��{��{
��{�{5�{k�{��{��{E�{�{ ��{ ��{"�{&z�{*��{+:�{.�{4��{5�{7��{?�{?��{Aw�{E��{H�{I0�{J��{KX�{R��{S3�{S��{W��{W��{`��{at�{ii�{l�{m��{u��{vD�{x��{�4�{���{��{�#�{���{�\�{���{���{���{���{���{��{���{���{���{�H�{�x�{���{���{���{�&�{���{��{�N�{�z�{�Y�{ʨ�{˸�{�d�{���{�!�{֗�{ש�{�+�{ٵ�{�f�{���{��{��{��{�@�{��{�Z�{�l�{��{��{�R�{��{��{��|h�|a�|,�|��|
�|M�|��|�|7�|<�|��|��|# �|&��|(X�|)��|-��|/�|1L�|94�|9n�|;��|;��|A8�|E2�|JF�|K2�|K>�|L �|O@�|Q��|T��|Z,�|^��|a��|b$�|d��|hC�|j��|q��|s,�|s��|t/�|w��|{]�|{��|P�|���|�h�|��|�*�|���|���|�[�|���|���|���|���|���|��|���|�g�|���|� �|�c�|�=�|�g�|���|��|�c�|��|�$�|۵�|��|��|�0�|�L�|���|���|�&�|���|��|��|���|���} �} ��}��}��}��}M�}��}��}H�}X�}Q�}!]�}$��}'��}'��}(��}*e�}*��}-��}.��}0��}17�}1Z�}2u�}3��}4�}Cy�}C��}F�}H�}H��}K��}NW�}N��}Q��}S|�}S��}V��}Z��}]��}_A�}f�}hV�}iN�}n�}y[�}{)�}{p�}|��}�}�m�}�S�}�'�}�p�}���}�b�}���}�f�}���}���}��}�j�}���}� �}�[�}�d�}�Z�}���}�E�}�F�}���}Ø�}��}�"�}���}���}�\�}�I�}�n�}ڸ�}�t�}���}���}��}�G�}�O�}�2�}��}���}���}���~-�~��~
��~4�~��~ ��~!s�~&��~,��~,��~-a�~.��~/��~8	�~9i�~<[�~@�~G��~J��~K+�~N��~P��~R>�~U��~