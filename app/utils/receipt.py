from datetime import datetime


def next_receipt_no(cursor, tenant_id: int, prefix: str) -> str:
    """
    Generate next receipt number atomically
    Format: {prefix}-{YYYYMM}-{6-digit-seq}
    Example: GANESH-202602-000123
    """
    now = datetime.now()
    yyyymm = now.strftime("%Y%m")
    
    # Ensure sequence exists
    cursor.execute(
        "SELECT last_no FROM ReceiptSequence WHERE tenant_id = %s FOR UPDATE",
        (tenant_id,)
    )
    
    result = cursor.fetchone()
    
    if not result:
        cursor.execute(
            "INSERT INTO ReceiptSequence(tenant_id, last_no) VALUES(%s, 0)",
            (tenant_id,)
        )
    
    # Increment atomically
    cursor.execute(
        """UPDATE ReceiptSequence 
           SET last_no = last_no + 1, updated_at = now() 
           WHERE tenant_id = %s 
           RETURNING last_no""",
        (tenant_id,)
    )
    
    result = cursor.fetchone()
    seq_number = str(result['last_no']).zfill(6)
    
    return f"{prefix}-{yyyymm}-{seq_number}"
