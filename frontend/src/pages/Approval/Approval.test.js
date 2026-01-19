import React from 'react';
import { render, screen, fireEvent, wait, within } from '@testing-library/react';
import Approval from './Approvals';
import { BrowserRouter } from 'react-router-dom';
import axios from 'axios';

jest.mock('axios');

/**
 * Test data matches the original Enzyme tests exactly.
 * Original tests used setState to inject this data; we use mocked axios instead.
 */
const mockOneBill = [
    {
        "id": 1,
        "report_dtm": "2020-11-04T17:39:21Z",
        "bill_start": "2020-11-04T17:39:22Z",
        "bill_end": "2020-11-04T17:39:23Z",
        "audit_status": "PROCESSING",
        "bill_transit": 2,
        "cost_mult": 2,
        "sid": 1,
        "stations": "WCPE",
        "year": 2020
    }
];

const mockThreeBills = [
    {
        "id": 1,
        "report_dtm": "2020-11-04T17:39:21Z",
        "bill_start": "2020-11-04T17:39:22Z",
        "bill_end": "2020-11-04T17:39:23Z",
        "audit_status": "PROCESSING",
        "bill_transit": 2,
        "cost_mult": 2,
        "sid": 1,
        "stations": "WCPE",
        "year": 2020
    },
    {
        "id": 2,
        "report_dtm": "2020-11-04T17:39:21Z",
        "bill_start": "2020-11-04T17:39:22Z",
        "bill_end": "2020-11-04T17:39:23Z",
        "audit_status": "PROCESSED",
        "bill_transit": 2,
        "cost_mult": 2,
        "sid": 1,
        "stations": "WCPE",
        "year": 2020
    },
    {
        "id": 3,
        "report_dtm": "2020-11-04T17:39:21Z",
        "bill_start": "2020-11-04T17:39:22Z",
        "bill_end": "2020-11-04T17:39:23Z",
        "audit_status": "UNUSABLE",
        "bill_transit": 2,
        "cost_mult": 2,
        "sid": 1,
        "stations": "WCPE",
        "year": 2020
    }
];

const renderApproval = () => {
    return render(
        <BrowserRouter>
            <Approval />
        </BrowserRouter>
    );
};

beforeEach(() => {
    jest.clearAllMocks();
    localStorage.clear();
    localStorage.setItem('user', 'test-token');
    // Mock window._env_ for API calls
    window._env_ = { BACKEND_BASE_URL: 'http://localhost/' };
});

/**
 * Original test: ReactDOM.render inside a BrowserRouter
 * Migration: Equivalent render using @testing-library/react
 */
describe("render without crashing", () => {
    it("renders the header", () => {
        axios.get.mockResolvedValue({ data: [] });
        renderApproval();
    })
})

/**
 * Original test: Used setState to set bills and checked state, then simulated
 * 'check' event on checkAllBox and verified behavior.
 *
 * Migration: We load bills via mocked axios, then click the select-all checkbox
 * and verify all bill checkboxes become checked.
 */
describe("handle select all checkbox", () => {
    it("changes all checkboxes to be selected", async () => {
        axios.get.mockResolvedValue({ data: mockOneBill });
        renderApproval();

        await wait(() => {
            expect(screen.getByText('WCPE')).toBeInTheDocument();
        });

        const checkboxes = screen.getAllByRole('checkbox');
        // First checkbox is the "check all" box
        const checkAllBox = checkboxes[0];

        fireEvent.click(checkAllBox);

        // Verify all checkboxes are now checked
        const allCheckboxes = screen.getAllByRole('checkbox');
        allCheckboxes.forEach(checkbox => {
            expect(checkbox).toBeChecked();
        });
    })
})

/**
 * Original test: shallow render with no setState, expect 2 TableRows
 * (the two header rows in the component)
 *
 * Migration: Render with empty data, verify no bill data rows are present.
 * Original verified row count = 2 (headers only). We verify no bill content.
 */
describe("no bills", () => {
    it("empty bill list", async () => {
        axios.get.mockResolvedValue({ data: [] });
        renderApproval();

        await wait(() => {
            expect(axios.get).toHaveBeenCalled();
        });

        // With no bills, there should be no bill station names in the table body
        expect(screen.queryByText('WCPE')).not.toBeInTheDocument();

        // Verify we have table structure (headers exist) but no data rows
        // Original: 2 rows total. Here we verify headers exist but no data.
        expect(screen.getByText('Radio Station')).toBeInTheDocument();
    })
})

/**
 * Original test: setState with 1 bill, expect 3 TableRows (2 headers + 1 data)
 *
 * Migration: Load 1 bill via axios mock, verify 1 data row appears.
 * We count rows to preserve behavioral equivalence with original test.
 */
describe("adding bills", () => {
    it("adding one bill", async () => {
        axios.get.mockResolvedValue({ data: mockOneBill });
        renderApproval();

        await wait(() => {
            expect(screen.getByText('WCPE')).toBeInTheDocument();
        });

        // Original expected 3 rows: 2 header rows + 1 data row
        // We verify by counting rows in the table
        const table = screen.getByRole('table');
        const rows = within(table).getAllByRole('row');
        expect(rows.length).toBe(3);
    })

    /**
     * Original test: setState with 3 bills, expect 5 TableRows (2 headers + 3 data)
     */
    it("adding three bills", async () => {
        axios.get.mockResolvedValue({ data: mockThreeBills });
        renderApproval();

        await wait(() => {
            expect(screen.getAllByText('WCPE').length).toBe(3);
        });

        // Original expected 5 rows: 2 header rows + 3 data rows
        const table = screen.getByRole('table');
        const rows = within(table).getAllByRole('row');
        expect(rows.length).toBe(5);
    })
})

/**
 * Original test: setState with bills/checked, simulate change on checkAllBox,
 * simulate click on rejectButton
 *
 * Migration: Load bills via mock, click select-all, click reject button,
 * verify axios.patch was called (the rejection API call)
 */
describe("removing all bills", () => {
    it("checking all bills and rejecting", async () => {
        axios.get.mockResolvedValue({ data: mockOneBill });
        axios.patch.mockResolvedValue({ data: {} });
        renderApproval();

        await wait(() => {
            expect(screen.getByText('WCPE')).toBeInTheDocument();
        });

        // Select all bills
        const checkboxes = screen.getAllByRole('checkbox');
        const checkAllBox = checkboxes[0];
        fireEvent.click(checkAllBox);

        // Click reject
        const rejectButton = screen.getByRole('button', { name: /reject/i });
        fireEvent.click(rejectButton);

        // Verify the rejection API call was made
        await wait(() => {
            expect(axios.patch).toHaveBeenCalledWith(
                expect.stringContaining('status=UNUSABLE'),
                null,
                expect.any(Object)
            );
        });
    })
})

/**
 * Original tests: setState with bills, simulate button clicks, verify row count
 * stayed at 3 (i.e., no crash, component still renders)
 *
 * Migration: Load bills, select a bill, click buttons, verify no errors.
 * Original tests were essentially verifying buttons were clickable without crashing.
 */
describe("dummy button clicks", () => {
    it("approve button click", async () => {
        axios.get.mockResolvedValue({ data: mockOneBill });
        axios.patch.mockResolvedValue({ data: {} });
        renderApproval();

        await wait(() => {
            expect(screen.getByText('WCPE')).toBeInTheDocument();
        });

        // Select the bill
        const checkboxes = screen.getAllByRole('checkbox');
        fireEvent.click(checkboxes[1]); // First data row checkbox

        // Click approve
        const approveButton = screen.getByRole('button', { name: /approve/i });
        fireEvent.click(approveButton);

        // Verify API call was made with PROCESSING status
        await wait(() => {
            expect(axios.patch).toHaveBeenCalledWith(
                expect.stringContaining('status=PROCESSING'),
                null,
                expect.any(Object)
            );
        });
    })

    it("reject button click", async () => {
        axios.get.mockResolvedValue({ data: mockOneBill });
        axios.patch.mockResolvedValue({ data: {} });
        renderApproval();

        await wait(() => {
            expect(screen.getByText('WCPE')).toBeInTheDocument();
        });

        // Select the bill
        const checkboxes = screen.getAllByRole('checkbox');
        fireEvent.click(checkboxes[1]); // First data row checkbox

        // Click reject
        const rejectButton = screen.getByRole('button', { name: /reject/i });
        fireEvent.click(rejectButton);

        // Verify API call was made with UNUSABLE status
        await wait(() => {
            expect(axios.patch).toHaveBeenCalledWith(
                expect.stringContaining('status=UNUSABLE'),
                null,
                expect.any(Object)
            );
        });
    })
})
