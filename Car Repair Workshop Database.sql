
-- Create Database
CREATE DATABASE dbfinalProject1;
USE dbfinalProject1;

-- Table: CarOwner
CREATE TABLE CarOwner (
    OID INT PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Contact NVARCHAR(20),
    Address NVARCHAR(255)
);

-- Table: Branch
CREATE TABLE Branch (
    BranchID INT PRIMARY KEY,
    BranchName NVARCHAR(100)
);

ALTER TABLE Branch
ADD ManagerName NVARCHAR(100),
    Address NVARCHAR(255);

-- Table: Car
CREATE TABLE Car (
    CarID INT PRIMARY KEY,
    Make NVARCHAR(50),
    Model NVARCHAR(50),
    OID INT,
    EntryDate DATE,
    BranchID INT,
    FOREIGN KEY (OID) REFERENCES CarOwner(OID),
    FOREIGN KEY (BranchID) REFERENCES Branch(BranchID)
);

-- Table: Mechanic
CREATE TABLE Mechanic (
    MechanicID INT PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Contact NVARCHAR(20),
    Address NVARCHAR(255),
    ServiceID INT,
    BranchID INT,
    Salary DECIMAL(10, 2),
    FOREIGN KEY (BranchID) REFERENCES Branch(BranchID)
);

-- Table: Services
CREATE TABLE Services (
    ServiceID INT PRIMARY KEY,
    ServiceName NVARCHAR(100),
    Cost DECIMAL(10, 2)
);

-- Table: Payments
CREATE TABLE Payments (
    PaymentID INT PRIMARY KEY,
    CarID INT,
    OID INT,
    TotalAmount DECIMAL(10, 2),
    PaymentStatus NVARCHAR(50),
    FOREIGN KEY (CarID) REFERENCES Car(CarID),
    FOREIGN KEY (OID) REFERENCES CarOwner(OID)
);

CREATE TABLE Supplier (
    SupplierID INT PRIMARY KEY,
    SupplierName VARCHAR(255) 
);


-- Table: Product
CREATE TABLE Product (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100),
    Cost DECIMAL(10, 2),
    AvailableUnits INT,
    SoldUnits INT DEFAULT 0
);

-- Table: ProductPurchase
CREATE TABLE ProductPurchase (
    PurchaseID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT,
    SupplierID INT,
    UnitPrice DECIMAL(10, 2),
    Quantity INT,
    PurchaseDate DATE,
    PaymentStatus NVARCHAR(50),
    BranchID INT,
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID),
    FOREIGN KEY (BranchID) REFERENCES Branch(BranchID)
);



-- Create BranchProduct table
CREATE TABLE BranchProduct (
    recordID INT PRIMARY KEY,
    ProductID INT,
    BranchID INT,
    AvailableUnits INT,
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID), 
    FOREIGN KEY (BranchID) REFERENCES Branch(BranchID)  
);

-- Table: ServiceRecord
CREATE TABLE ServiceRecord (
    ServiceRecordID INT PRIMARY KEY,
    CarID INT,
    ProductID INT,
    ServiceID INT,
    MechanicID INT,
    ServiceDate DATE,
    FOREIGN KEY (CarID) REFERENCES Car(CarID),
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    FOREIGN KEY (ServiceID) REFERENCES Services(ServiceID),
    FOREIGN KEY (MechanicID) REFERENCES Mechanic(MechanicID)
);


-- Insert entries into Branch table
INSERT INTO Branch (BranchID, ManagerName, Address) VALUES (1, 'David Warner', '123 Main St');
INSERT INTO Branch (BranchID, ManagerName, Address) VALUES (2, 'Jennifer Lawrence', '456 Oak Ave');
INSERT INTO Branch (BranchID, ManagerName, Address) VALUES (3, 'Edward Kenway', '789 Pine Ln');


DROP TABLE CarOwner;
DROP TABLE Car;
DROP TABLE Mechanic;
DROP TABLE Services;
DROP TABLE Branch;
DROP TABLE Supplier;
DROP TABLE Payments;
DROP TABLE Product;
DROP TABLE ProductPurchase;
DROP TABLE ServiceRecord;
DROP TABLE BranchProduct;

-- View Data
SELECT * FROM CarOwner;
SELECT * FROM Branch;
SELECT * FROM Car;
SELECT * FROM Mechanic;
SELECT * FROM Services;
SELECT * FROM Payments;
SELECT * FROM Product;
SELECT * FROM Supplier;


SELECT * FROM ProductPurchase;

SELECT * FROM BranchProduct;


SELECT * FROM ServiceRecord;



-----------Query-------------

SELECT 
    c.CarID,
    c.Make,
    c.Model,
    co.FirstName AS OwnerFirstName,
    co.LastName AS OwnerLastName,
    s.ServiceName,
    sr.ServiceDate,
    p.ProductName,
    pp.Quantity AS PurchasedQuantity,
    b.ManagerName AS BranchManager,
    sp.Name AS SupplierName
FROM Car c
JOIN CarOwner co ON c.OID = co.OID
JOIN ServiceRecord sr ON c.CarID = sr.CarID
JOIN Services s ON sr.ServiceID = s.ServiceID
JOIN Product p ON sr.ProductID = p.ProductID
LEFT JOIN ProductPurchase pp ON sr.ProductID = pp.ProductID
LEFT JOIN Branch b ON sr.BranchID = b.BranchID
LEFT JOIN Supplier sp ON pp.SupplierID = sp.SupplierID
WHERE c.CarID IN (
    SELECT CarID 
    FROM Payments 
    WHERE PaymentStatus = 'Paid' 
    GROUP BY CarID 
    HAVING SUM(TotalAmount) > 1000
)
ORDER BY sr.ServiceDate DESC;

----------------DENORMALIZED TABLE-------------------

CREATE TABLE DenormalizedCarInfo (
    CarID INT,
    Make VARCHAR(255),
    Model VARCHAR(255),
    OwnerFirstName VARCHAR(255),
    OwnerLastName VARCHAR(255),
    ServiceName VARCHAR(255),
    ServiceDate DATE,
    ProductName VARCHAR(255),
    PurchasedQuantity INT,
    BranchManager VARCHAR(255),
    SupplierName VARCHAR(255)
);


CREATE TABLE DenormalizedCarInfo (
    CarID INT,
    Make VARCHAR(255),
    Model VARCHAR(255),
    OwnerFirstName VARCHAR(255),
    OwnerLastName VARCHAR(255),
    ServiceName VARCHAR(255),
    ServiceDate DATE,
    ProductName VARCHAR(255),
    PurchasedQuantity INT,
    BranchManager VARCHAR(255),
    SupplierName VARCHAR(255)
);


-----------Views------------------

CREATE VIEW PaymentStatusView AS
SELECT p.PaymentID, p.CarID, c.Make, c.Model, p.TotalAmount, p.PaymentStatus, p.PaymentDate, co.FirstName, co.LastName
FROM Payments p
JOIN Car c ON p.CarID = c.CarID
JOIN CarOwner co ON c.OID = co.OID;

CREATE VIEW AvailableUnitsView AS
SELECT bp.ProductID, p.ProductName, SUM(bp.AvailableUnits) AS TotalAvailableUnits
FROM BranchProduct bp
JOIN Product p ON bp.ProductID = p.ProductID
GROUP BY bp.ProductID, p.ProductName;

-------------Audit Table-----------

CREATE TABLE CarAudit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    CarID INT,
    Make NVARCHAR(100),
    Model NVARCHAR(100),
    OID INT,
    EntryDate DATETIME,
    BranchID INT,
    Action NVARCHAR(50),  -- Action performed (INSERT, UPDATE, DELETE)
    ActionDate DATETIME DEFAULT GETDATE()
);


--------------Triggers----------------

CREATE TRIGGER Car_Audit_Trigger
ON Car
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF EXISTS(SELECT * FROM inserted)
    BEGIN
        INSERT INTO CarAudit (CarID, Make, Model, OID, EntryDate, BranchID, Action)
        SELECT 
            COALESCE(inserted.CarID, deleted.CarID),
            COALESCE(inserted.Make, deleted.Make),
            COALESCE(inserted.Model, deleted.Model),
            COALESCE(inserted.OID, deleted.OID),
            COALESCE(inserted.EntryDate, deleted.EntryDate),
            COALESCE(inserted.BranchID, deleted.BranchID),
            CASE 
                WHEN inserted.CarID IS NOT NULL AND deleted.CarID IS NULL THEN 'INSERT'
                WHEN inserted.CarID IS NOT NULL AND deleted.CarID IS NOT NULL THEN 'UPDATE'
                ELSE 'DELETE' 
            END
        FROM inserted
        FULL OUTER JOIN deleted ON inserted.CarID = deleted.CarID;
    END;
END;






--------------Procedures------------

-------get info on carowners-------
CREATE PROCEDURE GetCarOwners
AS
BEGIN
    SELECT * FROM CarOwner;
END;

EXEC GetCarOwners

2)
---------check car entry based on date-------------
CREATE PROCEDURE GetCarsByEntryDate
AS
BEGIN
    SELECT C.CarID, C.Make, C.Model, C.EntryDate
    FROM Car C
    ORDER BY C.EntryDate;
END;

exec GetCarsByEntryDate

3)
-----payment details by car-------
CREATE PROCEDURE GetPaymentDetailsByCar
    @CarID INT
AS
BEGIN
    SELECT * FROM Payments
    WHERE CarID = @CarID;
END;

DECLARE @CarID INT = 13; 
EXEC GetPaymentDetailsByCar @CarID;

4)
-------- product purchase by suuplier
CREATE PROCEDURE GetProductPurchasesBySupplier
    @SupplierID INT
AS
BEGIN
    SELECT PP.*, P.ProductName, S.Name AS SupplierName
    FROM ProductPurchase PP
    INNER JOIN Product P ON PP.ProductID = P.ProductID
    INNER JOIN Supplier S ON PP.SupplierID = S.SupplierID
    WHERE PP.SupplierID = @SupplierID;
END;

  
DECLARE @SupplierID INT = 4;
EXEC GetProductPurchasesBySupplier @SupplierID;



5)
-------Retrieve products available in a specific branch-----------
CREATE PROCEDURE GetBranchProductsByBranch
    @BranchID INT
AS
BEGIN
    SELECT BP.*, P.ProductName
    FROM BranchProduct BP
    INNER JOIN Product P ON BP.ProductID = P.ProductID
    WHERE BranchID = @BranchID;
END;

DECLARE @BranchID INT = 1; 
EXEC GetBranchProductsByBranch @BranchID;

6)
---get payments by status-------
CREATE PROCEDURE GetTotalPaymentsByStatus
    @PaymentStatus VARCHAR(255)
AS
BEGIN
    SELECT SUM(TotalAmount) AS TotalAmount
    FROM Payments
    WHERE PaymentStatus = @PaymentStatus;
END;

DECLARE @PaymentStatus VARCHAR(255) = 'Paid'; 
EXEC GetTotalPaymentsByStatus @PaymentStatus;

7)
------total revenue from each branch-------
CREATE PROCEDURE GetTotalRevenueByBranch
AS
BEGIN
    SELECT B.BranchID, B.ManagerName, SUM(PM.TotalAmount) AS TotalRevenue
    FROM Branch B
    LEFT JOIN Car C ON B.BranchID = C.BranchID
    LEFT JOIN Payments PM ON C.CarID = PM.CarID
    GROUP BY B.BranchID, B.ManagerName;
END;

EXEC GetTotalRevenueByBranch;

8)
------No of services each mechanic performed----
CREATE PROCEDURE GetMechanicWorkload
AS
BEGIN
    SELECT M.MechanicID, M.FirstName, M.LastName, M.BranchID, COUNT(SR.ServiceRecordID) AS Workload
    FROM Mechanic M
    LEFT JOIN ServiceRecord SR ON M.MechanicID = SR.MechanicID
    GROUP BY M.MechanicID, M.FirstName, M.LastName, M.BranchID;
END;

EXEC GetMechanicWorkload


9)
-------Get Total Monthly Salary Amount For Each Branch-------
CREATE PROCEDURE GetMonthlyExpenditureByBranch
AS
BEGIN
    SELECT
        B.BranchID,
        B.ManagerName,
        SUM(CAST(M.Salary AS decimal(18, 2))) AS TotalSalaries
    FROM
        Branch B
        LEFT JOIN Mechanic M ON B.BranchID = M.BranchID
    GROUP BY
        B.BranchID,
        B.ManagerName;
END;

EXEC GetMonthlyExpenditureByBranch


10)

--------Get Each Branch Performance With Total Cost Of Service Performed On Car---------
CREATE PROCEDURE GetBranchPerformance
AS
BEGIN
    SELECT
        B.BranchID,
        B.ManagerName,
        CAST(COUNT(DISTINCT C.CarID) AS bigint) AS TotalCars,
        CAST(COUNT(DISTINCT M.MechanicID) AS bigint) AS TotalMechanics,
        SUM(S.Cost) AS TotalServiceCost,
        CAST(AVG(CAST(M.Salary AS decimal(18, 2))) AS decimal(18, 2)) AS AverageMechanicSalary
    FROM
        Branch B
        LEFT JOIN Car C ON B.BranchID = C.BranchID
        LEFT JOIN Mechanic M ON B.BranchID = M.BranchID
        LEFT JOIN ServiceRecord SR ON C.CarID = SR.CarID
        LEFT JOIN Services S ON SR.ServiceID = S.ServiceID
    GROUP BY
        B.BranchID,
        B.ManagerName;
END;


EXEC  GetBranchPerformance


11)
CREATE VIEW PaymentDetailsView AS
SELECT
    P.PaymentID,
    P.TotalAmount,
    P.PaymentStatus,
    CO.OID,
    CO.FirstName AS OwnerFirstName,
    CO.LastName AS OwnerLastName,
    CO.Contact AS OwnerContact,
    CO.Address AS OwnerAddress,
    C.CarID,
    C.Make,
    C.Model,
    C.EntryDate,
    B.BranchID,
    B.ManagerName,
    B.Address AS BranchAddress
FROM Payments P
JOIN Car C ON P.CarID = C.CarID
JOIN CarOwner CO ON C.OID = CO.OID
JOIN Branch B ON C.BranchID = B.BranchID;

SELECT * FROM PaymentDetailsView;

12)
CREATE VIEW ServiceRecordDetailsView AS
SELECT
    SR.serviceRecordID,
    C.CarID,
    C.Make,
    C.Model,
    C.EntryDate,
    CO.OID,
    CO.FirstName AS OwnerFirstName,
    CO.LastName AS OwnerLastName,
    CO.Contact AS OwnerContact,
    CO.Address AS OwnerAddress,
    S.ServiceID,
    S.ServiceName,
    S.Cost AS ServiceCost,
    SR.MechanicID
FROM ServiceRecord SR
JOIN Car C ON SR.CarID = C.CarID
JOIN CarOwner CO ON C.OID = CO.OID
JOIN Services S ON SR.ServiceID = S.ServiceID;