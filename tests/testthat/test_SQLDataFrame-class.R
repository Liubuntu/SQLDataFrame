context("SQLDataFrame-class")

test.db <- system.file("inst/extdata/test.db", package = "SQLDataFrame")

test_that("SQLDataFrame constructor argument checking",
{
    ## not valid SQLDataFrame()
    expect_error(SQLDataFrame())

    ## missing "dbtable"
    expect_error(SQLDataFrame(dbname = test.db, dbkey = "sampleID"))

    ## non-existing "dbtable"
    expect_error(SQLDataFrame(
        dbname = test.db, dbtable = "random", dbkey = "sampleID"))

    ## "row.names" does not work
    expect_error(SQLDataFrame(
        dbname = test.db, dbtable = "colData", dbkey = "sampleID",
        row.names = letters), "unused argument")

    ## non-matching "col.names"
    expect_warning(SQLDataFrame(
        dbname = test.db, dbtable = "colData", dbkey = "sampleID",
        col.names = letters))
})


obj <- SQLDataFrame(
    dbname = test.db, dbtable = "colData", dbkey = "sampleID")

test_that("SQLDataFrame constructor works",
{
    ## check slot values / accessors
    expect_true(validObject(obj))
    exp <- c("dbtable", "dbkey", "dbnrows", "tblData", "indexes")
    expect_identical(exp, slotNames(obj))
    expect_identical(test.db, dbname(obj))
    expect_identical("colData", dbtable(obj))
    expect_identical("sampleID", dbkey(obj))
    expect_identical(c(26L, 2L), dim(obj))
    expect_identical(list(NULL, c("Treatment", "Ages")),
                     dimnames(obj))
    expect_identical(2L, length(obj))
})

test_that("validity,SQLDataFrame works",
{
    expect_error(initialize(obj, indexes = vector("list", 3)))
})

## utility functions
test_that("'.extract_tbl_from_SQLDataFrame' works",
{
    obj1 <- obj[1:5, 2, drop=FALSE]

    res <- .extract_tbl_from_SQLDataFrame(obj1)
    expect_true(is(res, "tbl_dbi")) 
    expect_true(is.na(nrow(res)))
    expect_identical(ncol(res), 2L)
    expect_identical(colnames(res), c("sampleID", "Ages"))

    ## always keep key column in tblData
    obj2 <- obj[, 1, drop=FALSE]
    res <- .extract_tbl_from_SQLDataFrame(obj2)
    expect_identical(ncol(res), 2L)
    expect_identical(colnames(res), c("sampleID", "Treatment"))
})

test_that("'.extract_tbl_rows_by_key' works",
{
    obj1 <- obj[, 2, drop=FALSE]
    tbl <- .extract_tbl_from_SQLDataFrame(obj1)
    res <- .extract_tbl_rows_by_key(tbl, dbkey(obj), 1:5)
    nrow <- res %>% summarize(n=n()) %>% pull(n)
    expect_identical(nrow, 5L)
    expect_identical(colnames(res), c(dbkey(obj), colnames(obj)[2]))
})

## coercion
test_that("'as.data.frame' works",
{
    obj1 <- obj[, 2, drop=FALSE]
    exp <- data.frame(sampleID = letters, Ages = obj1$Ages,
                      stringsAsFactors = FALSE)
    expect_identical(exp, as.data.frame(obj1))
})
