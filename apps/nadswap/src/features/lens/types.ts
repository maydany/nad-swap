export type LensStatus = 0 | 1 | 2;

export type LensPairViewStatuses = {
  staticStatus: LensStatus;
  dynamicStatus: LensStatus;
  userStatus: LensStatus;
  overallStatus: LensStatus;
};
