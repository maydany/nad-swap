import { RouterProvider, createBrowserRouter } from "react-router-dom";

import { SwapPage } from "../pages/SwapPage";

const router = createBrowserRouter([
  {
    path: "/",
    element: <SwapPage />
  }
]);

export const AppRouter = () => <RouterProvider router={router} />;
